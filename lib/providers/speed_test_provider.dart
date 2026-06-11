import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/speed_test_state.dart';

/// Time-bounded, windowed speed test against Cloudflare's public endpoints.
///
/// Design goals (in priority order):
///   1. Download AND upload both produce correct, stable numbers.
///   2. Works on any connection speed without timing out: each transfer runs
///      for a fixed *duration* (not a fixed *size*), then is stopped.
///   3. Accurate measurement: the speed is computed over a measurement
///      "window" that skips the first ~1.5s (TLS handshake + TCP slow-start +
///      socket-buffer fill) and the tail, so neither warmup nor teardown skews
///      the result.
class SpeedTestProvider with ChangeNotifier {
  SpeedTestState _state = const SpeedTestState();
  SpeedTestState get state => _state;

  bool _isCanceled = false;
  CancelToken? _activeToken;
  late Dio _dio;

  final List<int> _latencies = [];

  static const String _baseUrl = 'https://speed.cloudflare.com';
  static const String _downloadUrl = '$_baseUrl/__down';
  static const String _uploadUrl = '$_baseUrl/__up';

  // ---- Tunables -------------------------------------------------------------
  static const int _latencyPackets = 12;
  // How long each throughput phase actively transfers data.
  static const Duration _downloadDuration = Duration(seconds: 8);
  static const Duration _uploadDuration = Duration(seconds: 8);
  // Ignore the first part of each transfer (ramp-up) when computing the result.
  static const double _warmupSeconds = 1.5;
  // A request size large enough that it never finishes before the time limit,
  // even on very fast links (~1 Gbps * 8s ≈ 1 GB). The transfer is canceled at
  // the duration mark, so we never actually download/upload this much.
  static const int _downloadRequestBytes = 2000000000; // 2 GB ceiling
  static const int _uploadChunkSize = 64 * 1024;
  // ---------------------------------------------------------------------------

  String _measurementId = '';

  SpeedTestProvider() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      // Generous transport timeouts; phases are bounded by their own timers.
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'User-Agent': 'Tiksar VPN Speed Test'},
    ));
  }

  String _generateMeasurementId() =>
      (Random().nextDouble() * 1e16).round().toString();

  void stopTest() {
    _isCanceled = true;
    _activeToken?.cancel('User canceled');
    _activeToken = null;
    _latencies.clear();
    _state = const SpeedTestState();
    notifyListeners();
    debugPrint('🛑 Speed test stopped and reset');
  }

  Future<void> startTest() async {
    if (_state.step != SpeedTestStep.ready) {
      stopTest();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    _isCanceled = false;
    _measurementId = _generateMeasurementId();
    _latencies.clear();

    _state = const SpeedTestState(
      step: SpeedTestStep.loading,
      currentPhase: 'Initializing...',
    );
    notifyListeners();

    debugPrint('🚀 Speed test started');

    try {
      // 1) Latency / jitter
      await _runLatency();
      if (_isCanceled) return;

      // 2) Download
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
      await Future.delayed(const Duration(milliseconds: 250));
      if (_isCanceled) return;

      // 3) Upload
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
      debugPrint('🏁 Speed test completed');
    } catch (e) {
      debugPrint('❌ Speed test error: $e');
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

  // ---------------------------------------------------------------------------
  // Latency
  // ---------------------------------------------------------------------------
  Future<void> _runLatency() async {
    _state = _state.copyWith(
      step: SpeedTestStep.loading,
      currentPhase: 'Measuring latency...',
    );
    notifyListeners();

    int consecutiveFailures = 0;
    for (int i = 0; i < _latencyPackets; i++) {
      if (_isCanceled) return;
      final token = CancelToken();
      _activeToken = token;
      try {
        final sw = Stopwatch()..start();
        await _dio.get(
          '$_downloadUrl?bytes=0&measId=$_measurementId',
          options: Options(headers: {'Cache-Control': 'no-cache, no-store'}),
          cancelToken: token,
        );
        sw.stop();
        final latency = sw.elapsedMilliseconds;
        if (latency > 0 && latency < 5000) {
          _latencies.add(latency);
          consecutiveFailures = 0;
          _publishLatency(lastPing: latency);
        }
      } catch (e) {
        if (_isCanceled) return;
        consecutiveFailures++;
        if (consecutiveFailures >= 3) {
          throw Exception('Network connection failed');
        }
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }

    if (_latencies.isEmpty) throw Exception('Failed to measure latency');
  }

  void _publishLatency({required int lastPing}) {
    final avg =
        (_latencies.reduce((a, b) => a + b) / _latencies.length).round();
    _state = _state.copyWith(
      result: _state.result.copyWith(
        ping: _latencies.reduce(min),
        latency: avg,
        jitter: _jitter(),
      ),
    );
    notifyListeners();
  }

  int _jitter() {
    if (_latencies.length < 2) return 0;
    int sum = 0;
    for (int i = 1; i < _latencies.length; i++) {
      sum += (_latencies[i] - _latencies[i - 1]).abs();
    }
    return (sum / (_latencies.length - 1)).round();
  }

  // ---------------------------------------------------------------------------
  // Throughput (shared by download & upload)
  // ---------------------------------------------------------------------------
  /// Runs a single time-bounded transfer and returns the windowed speed in Mbps.
  Future<double> _runThroughput({required bool isUpload}) async {
    final duration = isUpload ? _uploadDuration : _downloadDuration;
    // Cumulative samples: [elapsedSeconds, cumulativeBytes].
    final List<List<double>> samples = [];
    final transferSw = Stopwatch();
    DateTime? lastUiUpdate;

    final token = CancelToken();
    _activeToken = token;

    // Timer that stops the transfer once the measurement duration elapses.
    Timer? stopTimer;

    void record(int cumulativeBytes) {
      if (!transferSw.isRunning) transferSw.start();
      final t = transferSw.elapsedMilliseconds / 1000.0;
      samples.add([t, cumulativeBytes.toDouble()]);

      // Drive the live gauge + progress bar.
      final now = DateTime.now();
      if (lastUiUpdate == null ||
          now.difference(lastUiUpdate!).inMilliseconds >= 120) {
        lastUiUpdate = now;
        final instant = _instantSpeedMbps(samples);
        _state = _state.copyWith(
          currentSpeed: _roundSpeed(instant),
          progress: (t / (duration.inMilliseconds / 1000.0)).clamp(0.0, 1.0),
        );
        notifyListeners();
      }
    }

    try {
      if (isUpload) {
        // Chunked upload: a generator yields zero-filled chunks. The generator
        // is naturally back-pressured by the real socket throughput, so the
        // bytes it has yielded ≈ the bytes actually accepted by the network.
        final chunk = Uint8List(_uploadChunkSize);
        int sent = 0;
        bool timeUp = false;

        Stream<List<int>> body() async* {
          transferSw.start();
          stopTimer = Timer(duration, () => timeUp = true);
          while (!timeUp && !_isCanceled) {
            yield chunk;
            sent += chunk.length;
            record(sent);
            // Yield to the event loop so the socket can drain and our stop
            // timer / cancellation can fire between chunks.
            await Future.delayed(Duration.zero);
          }
        }

        await _dio.post(
          '$_uploadUrl?measId=$_measurementId',
          data: body(),
          options: Options(
            headers: {
              'Content-Type': 'application/octet-stream',
              'Cache-Control': 'no-cache, no-store',
            },
            // No Content-Length => chunked transfer, so we can stop anytime.
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
          cancelToken: token,
        );
      } else {
        // Download a huge body and cancel it at the duration mark.
        stopTimer = Timer(duration, () {
          if (!token.isCancelled) token.cancel('measurement-window-complete');
        });

        await _dio.get<ResponseBody>(
          '$_downloadUrl?bytes=$_downloadRequestBytes&measId=$_measurementId',
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Cache-Control': 'no-cache, no-store',
              'Accept-Encoding': 'identity',
            },
          ),
          cancelToken: token,
        ).then((resp) async {
          int received = 0;
          await for (final part in resp.data!.stream) {
            if (_isCanceled || token.isCancelled) break;
            received += part.length;
            record(received);
          }
        });
      }
    } on DioException catch (e) {
      // Cancellation at the time limit is the expected, normal stop condition.
      if (e.type != DioExceptionType.cancel) {
        stopTimer?.cancel();
        if (_isCanceled) return 0.0;
        throw Exception('${isUpload ? 'Upload' : 'Download'} failed: $e');
      }
    } finally {
      stopTimer?.cancel();
    }

    if (_isCanceled) return 0.0;
    return _windowedSpeedMbps(samples, _warmupSeconds);
  }

  /// Speed over the steady-state window: total bits transferred after the
  /// warmup period, divided by the time spent in that window.
  double _windowedSpeedMbps(List<List<double>> samples, double warmupSec) {
    if (samples.length < 2) return 0.0;

    final endT = samples.last[0];
    final endB = samples.last[1];

    // If the whole transfer was shorter than the warmup, fall back to using it
    // all (better an approximate number than zero on a very fast/short run).
    if (endT <= warmupSec) {
      final dt = endT - samples.first[0];
      if (dt < 0.2) return 0.0;
      return (endB - samples.first[1]) * 8 / dt / 1e6;
    }

    // First sample at or after the warmup mark = window start.
    List<double> start = samples.first;
    for (final s in samples) {
      if (s[0] >= warmupSec) {
        start = s;
        break;
      }
    }
    final dt = endT - start[0];
    final db = endB - start[1];
    if (dt < 0.2 || db <= 0) return 0.0;
    return db * 8 / dt / 1e6;
  }

  /// Instantaneous speed over roughly the last second, for the live gauge.
  double _instantSpeedMbps(List<List<double>> samples) {
    if (samples.length < 2) return 0.0;
    final endT = samples.last[0];
    final endB = samples.last[1];
    List<double> start = samples.first;
    for (int i = samples.length - 1; i >= 0; i--) {
      if (endT - samples[i][0] >= 1.0) {
        start = samples[i];
        break;
      }
    }
    final dt = endT - start[0];
    final db = endB - start[1];
    if (dt < 0.15 || db <= 0) return 0.0;
    return db * 8 / dt / 1e6;
  }

  // ---------------------------------------------------------------------------
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
        jitter: _jitter(),
        packetLoss: 0,
      ),
    );
    notifyListeners();
    debugPrint(
        'Complete: ↓${download.toStringAsFixed(1)} ↑${upload.toStringAsFixed(1)} Mbps');
  }

  double _roundSpeed(double speed) {
    if (speed < 10) return (speed / 0.1).round() * 0.1;
    if (speed < 50) return (speed / 0.25).round() * 0.25;
    return (speed / 0.5).round() * 0.5;
  }

  void resetTest() => stopTest();
}
