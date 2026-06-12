import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/speed_test_state.dart';

class SpeedTestProvider with ChangeNotifier {
  SpeedTestState _state = const SpeedTestState();
  SpeedTestState get state => _state;

  bool _isCanceled = false;
  String _measurementId = '';
  final List<int> _latencies = [];

  // ── Endpoints ──────────────────────────────────────────────────────────────
  static const String _base = 'https://speed.cloudflare.com';
  static const String _downUrl = '$_base/__down';
  static const String _upUrl = '$_base/__up';

  // ── Tunables ────────────────────────────────────────────────────────────────
  static const int _downloadConnections = 6;
  static const int _uploadConnections = 4;
  static const Duration _downloadDuration = Duration(seconds: 12);
  static const Duration _uploadDuration = Duration(seconds: 10);
  static const double _warmupSeconds = 1.5;
  // Per-request payload sizes are intentionally large so that a single request
  // spans the whole measurement window on typical connections. This avoids the
  // gauge "freezing" and the buffer-fill spike: with a long-lived upload the OS
  // socket buffer fills once (inside the warmup window, so it is excluded) and
  // afterwards `onSendProgress` advances at the real network drain rate. A small
  // request instead finishes almost instantly into the socket buffer, reports a
  // single big jump, then stalls — which is the bug we are fixing.
  //
  // NOTE: Cloudflare's __down endpoint rejects bytes >= 100,000,000 with HTTP
  // 403, so the download payload must stay below that cap (50 MB is accepted and
  // is plenty to span the window with 6 parallel connections). The __up endpoint
  // takes the body we stream, so the upload payload is not subject to that cap.
  static const int _downloadReqBytes = 50 * 1000 * 1000;
  static const int _uploadReqBytes = 100 * 1000 * 1000;
  static const int _uploadChunkSize = 64 * 1024;
  static const int _latencyProbes = 20;
  static const Duration _sampleInterval = Duration(milliseconds: 100);

  // ── Per-phase state ─────────────────────────────────────────────────────────
  int _phaseBytes = 0;
  List<CancelToken> _phaseTokens = [];
  Timer? _sampler;

  SpeedTestProvider();

  Dio _createDio() {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {'User-Agent': 'TiksarVPN/SpeedTest'},
    ));
  }

  String _generateMeasurementId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

  // ── Public API ──────────────────────────────────────────────────────────────

  void stopTest() {
    _isCanceled = true;
    _cleanupPhase();
    _latencies.clear();
    _state = const SpeedTestState();
    notifyListeners();
    debugPrint('[SpeedTest] Stopped');
  }

  void resetTest() => stopTest();

  Future<void> startTest() async {
    if (_state.step != SpeedTestStep.ready) {
      stopTest();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _isCanceled = false;
    _measurementId = _generateMeasurementId();
    _latencies.clear();

    _state = const SpeedTestState(
      step: SpeedTestStep.loading,
      currentPhase: 'Initializing...',
    );
    notifyListeners();
    debugPrint('[SpeedTest] Started');

    try {
      // Phase 1: Latency
      await _runLatency();
      if (_isCanceled) return;

      // Phase 2: Download
      _state = _state.copyWith(
        step: SpeedTestStep.download,
        currentPhase: 'Measuring download...',
        progress: 0.0,
        currentSpeed: 0,
      );
      notifyListeners();

      final download = await _runThroughput(isUpload: false);
      if (_isCanceled) return;

      _state = _state.copyWith(
        result: _state.result.copyWith(downloadSpeed: download),
        currentSpeed: 0,
        progress: 1.0,
      );
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isCanceled) return;

      // Phase 3: Upload
      _state = _state.copyWith(
        step: SpeedTestStep.upload,
        currentPhase: 'Measuring upload...',
        progress: 0.0,
        currentSpeed: 0,
      );
      notifyListeners();

      final upload = await _runThroughput(isUpload: true);
      if (_isCanceled) return;

      _finalize(download: download, upload: upload);
      debugPrint('[SpeedTest] Complete: down=${download.toStringAsFixed(1)} up=${upload.toStringAsFixed(1)} Mbps');
    } catch (e) {
      debugPrint('[SpeedTest] Error: $e');
      if (!_isCanceled) {
        _state = _state.copyWith(
          step: SpeedTestStep.ready,
          errorMessage: 'test_failed',
          hadError: true,
          currentSpeed: 0,
        );
        notifyListeners();
      }
    }
  }

  // ── Latency ──────────────────────────────────────────────────────────────────

  Future<void> _runLatency() async {
    _state = _state.copyWith(
      step: SpeedTestStep.loading,
      currentPhase: 'Measuring latency...',
    );
    notifyListeners();

    final dio = _createDio();
    int failures = 0;

    try {
      for (int i = 0; i < _latencyProbes; i++) {
        if (_isCanceled) return;

        final token = CancelToken();
        try {
          final sw = Stopwatch()..start();
          await dio.get(
            '$_downUrl?bytes=0&measId=$_measurementId&r=${Random().nextInt(99999)}',
            options: Options(headers: {'Cache-Control': 'no-cache, no-store'}),
            cancelToken: token,
          );
          sw.stop();

          final ms = sw.elapsedMilliseconds;
          if (ms > 0 && ms < 5000) {
            _latencies.add(ms);
            failures = 0;
            _publishLatency();
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) return;
          failures++;
          if (failures >= 5) throw Exception('Network unreachable');
        }

        if (i < _latencyProbes - 1) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } finally {
      dio.close();
    }

    if (_latencies.isEmpty) throw Exception('Latency measurement failed');
  }

  void _publishLatency() {
    if (_latencies.isEmpty) return;
    final sorted = List<int>.from(_latencies)..sort();
    final median = sorted[sorted.length ~/ 2];
    final minPing = sorted.first;

    _state = _state.copyWith(
      result: _state.result.copyWith(
        ping: minPing,
        latency: median,
        jitter: _computeJitter(),
      ),
    );
    notifyListeners();
  }

  int _computeJitter() {
    if (_latencies.length < 2) return 0;
    int sum = 0;
    for (int i = 1; i < _latencies.length; i++) {
      sum += (_latencies[i] - _latencies[i - 1]).abs();
    }
    return (sum / (_latencies.length - 1)).round();
  }

  // ── Throughput ──────────────────────────────────────────────────────────────

  Future<double> _runThroughput({required bool isUpload}) async {
    final duration = isUpload ? _uploadDuration : _downloadDuration;
    final connections = isUpload ? _uploadConnections : _downloadConnections;
    final totalMs = duration.inMilliseconds;

    // Fresh state for this phase
    _phaseBytes = 0;
    _phaseTokens = [];

    final dio = _createDio();
    final samples = <_Sample>[];
    final phaseSw = Stopwatch()..start();

    // Spawn workers
    final workers = <Future<void>>[];
    for (int i = 0; i < connections; i++) {
      final token = CancelToken();
      _phaseTokens.add(token);
      workers.add(
        isUpload
            ? _uploadWorker(dio, token)
            : _downloadWorker(dio, token),
      );
    }

    // Periodic sampling for live gauge
    _sampler = Timer.periodic(_sampleInterval, (_) {
      if (_isCanceled) return;
      final t = phaseSw.elapsedMilliseconds / 1000.0;
      final b = _phaseBytes;
      samples.add(_Sample(t, b));

      final instant = _computeInstantSpeed(samples);
      _state = _state.copyWith(
        currentSpeed: _roundSpeed(instant),
        progress: (phaseSw.elapsedMilliseconds / totalMs).clamp(0.0, 1.0),
      );
      notifyListeners();
    });

    // Wait for the measurement duration
    await Future.delayed(duration);

    // Stop sampling
    _sampler?.cancel();
    _sampler = null;
    phaseSw.stop();

    // Final sample
    samples.add(_Sample(phaseSw.elapsedMilliseconds / 1000.0, _phaseBytes));

    // Cancel all workers for this phase
    for (final t in _phaseTokens) {
      if (!t.isCancelled) t.cancel('phase-done');
    }
    _phaseTokens = [];

    // Small delay for workers to unwind
    await Future.delayed(const Duration(milliseconds: 100));
    dio.close();

    if (_isCanceled) return 0.0;
    return _computeWindowedSpeed(samples);
  }

  Future<void> _downloadWorker(Dio dio, CancelToken token) async {
    while (!_isCanceled && !token.isCancelled) {
      try {
        final resp = await dio.get<ResponseBody>(
          '$_downUrl?bytes=$_downloadReqBytes&measId=$_measurementId&r=${Random().nextInt(99999)}',
          options: Options(
            responseType: ResponseType.stream,
            headers: const {
              'Cache-Control': 'no-cache, no-store',
              'Accept-Encoding': 'identity',
            },
          ),
          cancelToken: token,
        );

        await for (final chunk in resp.data!.stream) {
          if (_isCanceled || token.isCancelled) return;
          _phaseBytes += chunk.length;
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) return;
        if (_isCanceled || token.isCancelled) return;
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {
        if (_isCanceled || token.isCancelled) return;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _uploadWorker(Dio dio, CancelToken token) async {
    final chunk = Uint8List(_uploadChunkSize);
    while (!_isCanceled && !token.isCancelled) {
      int prevSent = 0;

      Stream<List<int>> body() async* {
        int produced = 0;
        while (produced < _uploadReqBytes &&
            !_isCanceled &&
            !token.isCancelled) {
          final remaining = _uploadReqBytes - produced;
          final size = remaining >= chunk.length ? chunk.length : remaining;
          yield size == chunk.length ? chunk : Uint8List(size);
          produced += size;
        }
      }

      try {
        await dio.post(
          '$_upUrl?measId=$_measurementId',
          data: body(),
          options: Options(
            headers: {
              'Content-Type': 'application/octet-stream',
              'Content-Length': _uploadReqBytes,
              'Cache-Control': 'no-cache, no-store',
            },
          ),
          onSendProgress: (sent, total) {
            final delta = sent - prevSent;
            if (delta > 0) {
              _phaseBytes += delta;
              prevSent = sent;
            }
          },
          cancelToken: token,
        );
        // Request completed: reset for next iteration
        prevSent = 0;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) return;
        if (_isCanceled || token.isCancelled) return;
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {
        if (_isCanceled || token.isCancelled) return;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  // ── Speed Calculation ───────────────────────────────────────────────────────

  double _computeWindowedSpeed(List<_Sample> samples) {
    if (samples.length < 2) return 0.0;

    final endT = samples.last.time;
    final endB = samples.last.bytes.toDouble();

    // If total time < warmup, use the entire duration
    if (endT <= _warmupSeconds) {
      final dt = endT - samples.first.time;
      if (dt < 0.3) return 0.0;
      return (endB - samples.first.bytes) * 8.0 / dt / 1e6;
    }

    // Find first sample after warmup
    _Sample? start;
    for (final s in samples) {
      if (s.time >= _warmupSeconds) {
        start = s;
        break;
      }
    }
    if (start == null) return 0.0;

    final dt = endT - start.time;
    final db = endB - start.bytes;
    if (dt < 0.3 || db <= 0) return 0.0;
    return db * 8.0 / dt / 1e6;
  }

  double _computeInstantSpeed(List<_Sample> samples) {
    if (samples.length < 2) return 0.0;

    final end = samples.last;

    // During warmup the socket send buffer is filling, which makes upload
    // briefly read far above the real rate (a one-time spike). Keep that out of
    // the live gauge entirely: show nothing until warmup has passed, and never
    // let the measurement window reach back into the warmup region.
    if (end.time < _warmupSeconds) return 0.0;

    // Trailing ~1s window, clamped so it never starts before the warmup point.
    final windowStart = max(_warmupSeconds, end.time - 1.0);
    _Sample start = samples.first;
    for (final s in samples) {
      if (s.time <= windowStart) {
        start = s;
      } else {
        break;
      }
    }
    if (start.time < _warmupSeconds) {
      for (final s in samples) {
        if (s.time >= _warmupSeconds) {
          start = s;
          break;
        }
      }
    }

    final dt = end.time - start.time;
    final db = (end.bytes - start.bytes).toDouble();
    if (dt < 0.2 || db <= 0) return 0.0;
    return db * 8.0 / dt / 1e6;
  }

  // ── Finalize ────────────────────────────────────────────────────────────────

  void _finalize({required double download, required double upload}) {
    _state = _state.copyWith(
      step: SpeedTestStep.ready,
      progress: 1.0,
      currentSpeed: 0,
      testCompleted: true,
      hadError: false,
      clearErrorMessage: true,
      result: SpeedTestResult(
        downloadSpeed: download,
        uploadSpeed: upload,
        ping: _latencies.isEmpty ? 0 : _latencies.reduce(min),
        latency: _latencies.isEmpty
            ? 0
            : (_latencies.reduce((a, b) => a + b) / _latencies.length).round(),
        jitter: _computeJitter(),
        packetLoss: 0,
      ),
    );
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _cleanupPhase() {
    _sampler?.cancel();
    _sampler = null;
    for (final t in _phaseTokens) {
      if (!t.isCancelled) t.cancel('stopped');
    }
    _phaseTokens = [];
    _phaseBytes = 0;
  }

  double _roundSpeed(double speed) {
    if (speed <= 0) return 0;
    if (speed < 10) return double.parse(speed.toStringAsFixed(1));
    if (speed < 100) return double.parse(speed.toStringAsFixed(1));
    return speed.roundToDouble();
  }

  @override
  void dispose() {
    _isCanceled = true;
    _cleanupPhase();
    super.dispose();
  }
}

class _Sample {
  final double time;
  final int bytes;
  const _Sample(this.time, this.bytes);
}
