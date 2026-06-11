import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/speed_test_state.dart';
import '../services/speed_test/speed_test_api.dart';
import '../services/speed_test/speed_measurement_config.dart';
import '../services/speed_test/latency_measurement_service.dart';
import '../services/speed_test/download_measurement_service.dart';
import '../services/speed_test/upload_measurement_service.dart';
import '../services/speed_test/results_calculator_service.dart';

/// Cloudflare speed test using the multi-size + 90th-percentile method.
///
/// Rather than one long time-bounded transfer (which gave unstable/zero upload
/// numbers), this runs a sequence of fixed-size transfers — small payloads to
/// gauge slow links, large payloads to find the ceiling on fast ones — and
/// reports the 90th-percentile speed. The heavy lifting lives in the
/// per-phase services under `services/speed_test/`; this class orchestrates the
/// sequence and maps progress onto [SpeedTestState] for the existing UI.
class SpeedTestProvider with ChangeNotifier {
  SpeedTestState _state = const SpeedTestState();
  SpeedTestState get state => _state;

  late final Dio _dio;
  late final SpeedTestApi _api;

  bool _isCanceled = false;
  String _measurementId = '';

  final List<double> _downloadSpeeds = [];
  final List<double> _uploadSpeeds = [];
  final List<int> _latencies = [];

  SpeedTestProvider() {
    _dio = Dio(BaseOptions(
      connectTimeout: SpeedMeasurementConfig.connectTimeout,
      receiveTimeout: SpeedMeasurementConfig.receiveTimeout,
      sendTimeout: SpeedMeasurementConfig.sendTimeout,
      headers: {'User-Agent': 'Tiksar VPN Speed Test'},
    ));
    _api = SpeedTestApi(_dio);
  }

  String _generateMeasurementId() =>
      (Random().nextDouble() * 1e16).round().toString();

  // ── Public API (unchanged for the UI) ──────────────────────────────────────

  void stopTest() {
    _isCanceled = true;
    _downloadSpeeds.clear();
    _uploadSpeeds.clear();
    _latencies.clear();
    _state = const SpeedTestState();
    notifyListeners();
    debugPrint('🛑 Speed test stopped and reset');
  }

  void resetTest() => stopTest();

  Future<void> startTest() async {
    if (_state.step != SpeedTestStep.ready) {
      stopTest();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    _isCanceled = false;
    _measurementId = _generateMeasurementId();
    _downloadSpeeds.clear();
    _uploadSpeeds.clear();
    _latencies.clear();

    _state = const SpeedTestState(
      step: SpeedTestStep.loading,
      currentPhase: 'Initializing...',
    );
    notifyListeners();
    debugPrint('🚀 Cloudflare speed test started');

    try {
      await _runMeasurementSequence();
      if (_isCanceled) return;
      _calculateFinalResults();
      _checkConnectionStability();
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

  // ── Sequence orchestration ─────────────────────────────────────────────────

  Future<void> _runMeasurementSequence() async {
    String currentPhase = '';

    for (int i = 0; i < SpeedMeasurementConfig.measurements.length; i++) {
      if (_isCanceled) return;

      final measurement = SpeedMeasurementConfig.measurements[i];
      final progress = (i + 1) / SpeedMeasurementConfig.totalMeasurements;
      final type = measurement['type'] as String;

      // Animate the bar back to 0 when crossing into a new phase.
      SpeedTestStep? nextStep;
      if (type == 'latency' && currentPhase != 'loading') {
        nextStep = SpeedTestStep.loading;
        currentPhase = 'loading';
      } else if (type == 'download' && currentPhase != 'download') {
        nextStep = SpeedTestStep.download;
        currentPhase = 'download';
      } else if (type == 'upload' && currentPhase != 'upload') {
        nextStep = SpeedTestStep.upload;
        currentPhase = 'upload';
      }

      if (nextStep != null) {
        if (i > 0 && _state.progress > 0) {
          _state = _state.copyWith(progress: 0.0, currentSpeed: 0);
          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 1200));
          if (_isCanceled) return;
        }
        _state = _state.copyWith(step: nextStep);
        notifyListeners();
      }

      switch (type) {
        case 'latency':
          await _runLatency(measurement);
          break;
        case 'download':
          await _runDownload(measurement, progress);
          break;
        case 'upload':
          await _runUpload(measurement, progress);
          break;
      }

      await Future.delayed(SpeedMeasurementConfig.measurementDelay);
    }
  }

  Future<void> _runLatency(Map<String, dynamic> config) async {
    _state = _state.copyWith(
      step: SpeedTestStep.loading,
      currentPhase: 'Measuring latency...',
    );
    notifyListeners();

    final service = LatencyMeasurementService(
      api: _api,
      measurementId: _measurementId,
      isCanceledCheck: () => _isCanceled,
      onMetricsUpdate: (ping, latency, jitter) {
        _state = _state.copyWith(
          result: _state.result.copyWith(
            ping: ping,
            latency: latency,
            jitter: jitter,
          ),
        );
        notifyListeners();
      },
    );

    await service.runMeasurement(config);
    _latencies.addAll(service.latencies);
  }

  Future<void> _runDownload(Map<String, dynamic> config, double progress) async {
    _state = _state.copyWith(
      step: SpeedTestStep.download,
      currentPhase: 'Measuring download...',
      progress: progress,
    );
    notifyListeners();

    final service = DownloadMeasurementService(
      api: _api,
      measurementId: _measurementId,
      isCanceledCheck: () => _isCanceled,
      onSpeedUpdate: (speed) {
        _state = _state.copyWith(currentSpeed: speed);
        notifyListeners();
      },
      onMetricsUpdate:
          (percentileSpeed, avgSpeed, currentPing, avgLatency, jitter) {
        _state = _state.copyWith(
          currentSpeed: avgSpeed,
          result: _state.result.copyWith(
            downloadSpeed: percentileSpeed,
            ping: currentPing,
            latency: avgLatency,
            jitter: jitter,
          ),
        );
        notifyListeners();
      },
      latencies: _latencies,
    );

    await service.runMeasurement(config);
    _downloadSpeeds.addAll(service.downloadSpeeds);
  }

  Future<void> _runUpload(Map<String, dynamic> config, double progress) async {
    _state = _state.copyWith(
      step: SpeedTestStep.upload,
      currentPhase: 'Measuring upload...',
      progress: progress,
    );
    notifyListeners();

    final service = UploadMeasurementService(
      api: _api,
      measurementId: _measurementId,
      isCanceledCheck: () => _isCanceled,
      onSpeedUpdate: (speed) {
        _state = _state.copyWith(currentSpeed: speed);
        notifyListeners();
      },
      onMetricsUpdate: (percentileSpeed, avgSpeed, jitter, packetLoss) {
        _state = _state.copyWith(
          currentSpeed: avgSpeed,
          result: _state.result.copyWith(
            uploadSpeed: percentileSpeed,
            jitter: jitter,
            packetLoss: packetLoss,
          ),
        );
        notifyListeners();
      },
      latencies: _latencies,
      measurements: SpeedMeasurementConfig.measurements,
    );

    await service.runMeasurement(config);
    _uploadSpeeds.addAll(service.uploadSpeeds);
  }

  // ── Finalization ────────────────────────────────────────────────────────────

  void _calculateFinalResults() {
    final result = ResultsCalculatorService.calculateFinalResults(
      downloadSpeeds: _downloadSpeeds,
      uploadSpeeds: _uploadSpeeds,
      latencies: _latencies,
      measurements: SpeedMeasurementConfig.measurements,
    );

    _state = _state.copyWith(
      result: result,
      step: SpeedTestStep.ready,
      progress: 1.0,
      currentSpeed: 0,
      currentPhase: 'Test completed',
      testCompleted: true,
      hadError: false,
      clearErrorMessage: true,
    );
    notifyListeners();
    debugPrint(
        'Complete: ↓${result.downloadSpeed.toStringAsFixed(1)} ↑${result.uploadSpeed.toStringAsFixed(1)} Mbps');
  }

  void _checkConnectionStability() {
    final isStable =
        ResultsCalculatorService.checkConnectionStability(_state.result);
    if (!isStable) {
      _state = _state.copyWith(
        step: SpeedTestStep.ready,
        isConnectionStable: false,
        errorMessage: 'unstable_connection',
        hadError: true,
      );
      notifyListeners();
    }
  }
}
