import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/speed_test_state.dart';

class SpeedTestProvider with ChangeNotifier {
  SpeedTestState _state = const SpeedTestState();
  SpeedTestState get state => _state;

  bool _isCanceled = false;
  CancelToken? _cancelToken;
  late Dio _dio;

  final List<int> _latencies = [];
  final List<double> _downloadSpeeds = [];
  final List<double> _uploadSpeeds = [];

  static const String _downloadUrl = 'https://speed.cloudflare.com/__down';
  static const String _uploadUrl = 'https://speed.cloudflare.com/__up';

  SpeedTestProvider() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
    ));
  }

  void stopTest() {
    _isCanceled = true;
    _cancelToken?.cancel('User canceled');
    _cancelToken = null;
    _latencies.clear();
    _downloadSpeeds.clear();
    _uploadSpeeds.clear();
    _state = const SpeedTestState();
    notifyListeners();
  }

  Future<void> startTest() async {
    if (_state.step != SpeedTestStep.ready) {
      stopTest();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isCanceled = false;
    _cancelToken = CancelToken();
    _latencies.clear();
    _downloadSpeeds.clear();
    _uploadSpeeds.clear();

    _state = const SpeedTestState(step: SpeedTestStep.loading);
    notifyListeners();

    try {
      await _testLatency();
      if (_isCanceled) return;

      await _testDownload();
      if (_isCanceled) return;

      await _testUpload();
      if (_isCanceled) return;

      _finishTest();
    } catch (e) {
      debugPrint('Speed test error: $e');
      if (!_isCanceled) {
        _state = _state.copyWith(
          step: SpeedTestStep.ready,
          errorMessage: 'تست سرعت با خطا مواجه شد',
          hadError: true,
        );
        notifyListeners();
      }
    }
  }


  Future<void> _testLatency() async {
    debugPrint('Testing latency...');

    try {
      await _dio.head('$_downloadUrl?bytes=0');
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < 10; i++) {
      if (_isCanceled) return;

      try {
        final sw = Stopwatch()..start();
        await _dio.head('$_downloadUrl?bytes=0', cancelToken: _cancelToken);
        sw.stop();

        final latency = sw.elapsedMilliseconds;
        if (latency > 0 && latency < 5000) {
          _latencies.add(latency);
        }

        _state = _state.copyWith(
          progress: (i + 1) / 10,
          result: _state.result.copyWith(
            ping: _latencies.isNotEmpty ? _latencies.reduce(min) : 0,
            jitter: _calcJitter(),
          ),
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Ping failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_latencies.isEmpty) {
      throw Exception('Latency test failed');
    }
  }

  Future<void> _testDownload() async {
    debugPrint('Testing download...');

    _state = _state.copyWith(
      step: SpeedTestStep.download,
      progress: 0,
      currentSpeed: 0,
    );
    notifyListeners();

    final testSizes = [100000, 1000000, 5000000, 10000000, 25000000];

    for (int i = 0; i < testSizes.length; i++) {
      if (_isCanceled) return;

      final bytes = testSizes[i];
      final speed = await _measureDownload(bytes);

      if (speed > 0) {
        _downloadSpeeds.add(speed);
        final avgSpeed = _calcAverage(_downloadSpeeds);

        _state = _state.copyWith(
          progress: (i + 1) / testSizes.length,
          currentSpeed: avgSpeed,
          result: _state.result.copyWith(downloadSpeed: avgSpeed),
        );
        notifyListeners();

        if (avgSpeed < 1 && i >= 2) break;
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<double> _measureDownload(int bytes) async {
    final sw = Stopwatch()..start();
    int received = 0;

    try {
      await _dio.get<List<int>>(
        '$_downloadUrl?bytes=$bytes',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Cache-Control': 'no-cache, no-store'},
        ),
        cancelToken: _cancelToken,
        onReceiveProgress: (recv, total) {
          if (_isCanceled) return;
          received = recv;
          final elapsed = sw.elapsedMilliseconds / 1000.0;
          if (elapsed > 0.2) {
            final speed = (recv * 8) / elapsed / 1000000;
            _state = _state.copyWith(currentSpeed: speed);
            notifyListeners();
          }
        },
      );

      sw.stop();
      final seconds = sw.elapsedMilliseconds / 1000.0;
      if (seconds < 0.05) return 0;
      return (received * 8) / seconds / 1000000;
    } catch (e) {
      sw.stop();
      if (received > 0 && sw.elapsedMilliseconds > 100) {
        return (received * 8) / (sw.elapsedMilliseconds / 1000.0) / 1000000;
      }
      return 0;
    }
  }


  Future<void> _testUpload() async {
    debugPrint('Testing upload...');

    _state = _state.copyWith(
      step: SpeedTestStep.upload,
      progress: 0,
      currentSpeed: 0,
    );
    notifyListeners();

    final testSizes = [100000, 500000, 1000000, 2000000, 5000000];

    for (int i = 0; i < testSizes.length; i++) {
      if (_isCanceled) return;

      final bytes = testSizes[i];
      final speed = await _measureUpload(bytes);

      if (speed > 0) {
        _uploadSpeeds.add(speed);
        final avgSpeed = _calcAverage(_uploadSpeeds);

        _state = _state.copyWith(
          progress: (i + 1) / testSizes.length,
          currentSpeed: avgSpeed,
          result: _state.result.copyWith(uploadSpeed: avgSpeed),
        );
        notifyListeners();

        if (avgSpeed < 0.5 && i >= 2) break;
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<double> _measureUpload(int bytes) async {
    final data = Uint8List(bytes);
    final random = Random();
    for (int i = 0; i < min(4096, bytes); i++) {
      data[i] = random.nextInt(256);
    }

    final sw = Stopwatch()..start();
    int sent = 0;

    try {
      await _dio.post(
        _uploadUrl,
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/octet-stream'},
        ),
        cancelToken: _cancelToken,
        onSendProgress: (s, total) {
          if (_isCanceled) return;
          sent = s;
          final elapsed = sw.elapsedMilliseconds / 1000.0;
          if (elapsed > 0.2) {
            final speed = (s * 8) / elapsed / 1000000;
            _state = _state.copyWith(currentSpeed: speed);
            notifyListeners();
          }
        },
      );

      sw.stop();
      final seconds = sw.elapsedMilliseconds / 1000.0;
      if (seconds < 0.05) return 0;
      return (bytes * 8) / seconds / 1000000;
    } catch (e) {
      sw.stop();
      if (sent > 0 && sw.elapsedMilliseconds > 100) {
        return (sent * 8) / (sw.elapsedMilliseconds / 1000.0) / 1000000;
      }
      return 0;
    }
  }

  void _finishTest() {
    final download = _downloadSpeeds.isEmpty ? 0.0 : _calcAverage(_downloadSpeeds);
    final upload = _uploadSpeeds.isEmpty ? 0.0 : _calcAverage(_uploadSpeeds);
    final ping = _latencies.isEmpty ? 0 : _latencies.reduce(min);

    _state = _state.copyWith(
      step: SpeedTestStep.ready,
      progress: 1.0,
      currentSpeed: 0,
      testCompleted: true,
      hadError: false,
      result: SpeedTestResult(
        downloadSpeed: download,
        uploadSpeed: upload,
        ping: ping,
        latency: _latencies.isEmpty ? 0 : (_latencies.reduce((a, b) => a + b) ~/ _latencies.length),
        jitter: _calcJitter(),
        packetLoss: 0,
      ),
    );
    notifyListeners();

    debugPrint('Test Complete: Download=${download.toStringAsFixed(1)}Mbps, Upload=${upload.toStringAsFixed(1)}Mbps, Ping=${ping}ms');
  }

  double _calcAverage(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;
    final relevant = values.length > 1 ? values.sublist(1) : values;
    return relevant.reduce((a, b) => a + b) / relevant.length;
  }

  int _calcJitter() {
    if (_latencies.length < 2) return 0;
    int sum = 0;
    for (int i = 1; i < _latencies.length; i++) {
      sum += (_latencies[i] - _latencies[i - 1]).abs();
    }
    return sum ~/ (_latencies.length - 1);
  }

  void resetTest() => stopTest();
}
