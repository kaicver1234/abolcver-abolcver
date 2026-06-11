import 'package:flutter/foundation.dart';
import 'speed_test_api.dart';
import 'speed_measurement_config.dart';

/// Downloads a series of fixed-size payloads and reports throughput.
///
/// Each transfer completes fully, so its wall-clock duration gives an accurate
/// speed. The reported download figure is the 90th percentile across samples —
/// robust against the occasional slow request without inflating on outliers.
class DownloadMeasurementService {
  final SpeedTestApi api;
  final String measurementId;
  final bool Function() isCanceledCheck;
  final void Function(double speed) onSpeedUpdate;
  final void Function(double percentileSpeed, double avgSpeed, int currentPing,
      int avgLatency, int jitter) onMetricsUpdate;

  final List<double> downloadSpeeds = [];
  final List<int> latencies;

  DownloadMeasurementService({
    required this.api,
    required this.measurementId,
    required this.isCanceledCheck,
    required this.onSpeedUpdate,
    required this.onMetricsUpdate,
    required this.latencies,
  });

  Future<void> runMeasurement(Map<String, dynamic> config) async {
    final bytes = config['bytes'] as int;
    final count = config['count'] as int;
    final sizeLabel = SpeedMeasurementConfig.formatBytes(bytes);
    int consecutiveFailures = 0;

    for (int i = 0; i < count; i++) {
      if (isCanceledCheck()) {
        debugPrint('🛑 Download measurement canceled');
        return;
      }

      try {
        final speed = await _measureSpeed(bytes);
        if (speed > 0) {
          downloadSpeeds.add(speed);
          consecutiveFailures = 0;

          final percentileSpeed = _calculatePercentile(downloadSpeeds, 0.9);
          final avgSpeed =
              downloadSpeeds.reduce((a, b) => a + b) / downloadSpeeds.length;
          final currentPing = latencies.isNotEmpty ? latencies.last : 0;
          final avgLatency = latencies.isNotEmpty
              ? (latencies.reduce((a, b) => a + b) / latencies.length).round()
              : 0;

          onMetricsUpdate(
              percentileSpeed, avgSpeed, currentPing, avgLatency, _jitter());

          debugPrint(
              '   📥 Download ${i + 1}/$count ($sizeLabel): ${speed.toStringAsFixed(2)} Mbps (p90: ${percentileSpeed.toStringAsFixed(2)})');
        }
      } catch (e) {
        consecutiveFailures++;
        debugPrint('   ❌ Download measurement ${i + 1} failed: $e');
        if (consecutiveFailures >= SpeedMeasurementConfig.maxConsecutiveFailures) {
          throw Exception('Network connection lost during download test.');
        }
      }

      await Future.delayed(SpeedMeasurementConfig.measurementDelay);
    }
  }

  Future<double> _measureSpeed(int bytes) async {
    if (isCanceledCheck()) return 0.0;

    final startTime = DateTime.now();
    DateTime? lastUpdateTime;

    final response = await api.downloadTest(
      bytes: bytes,
      measurementId: measurementId,
      during: 'download',
      onReceiveProgress: (received, total) {
        final now = DateTime.now();
        final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
        if (!isCanceledCheck() &&
            elapsed > 0.05 &&
            (lastUpdateTime == null ||
                now.difference(lastUpdateTime!).inMilliseconds > 100)) {
          final mbps = (received * 8) / elapsed / 1000000;
          onSpeedUpdate(SpeedMeasurementConfig.roundSpeed(mbps));
          lastUpdateTime = now;
        }
      },
    );

    if (isCanceledCheck()) return 0.0;

    final durationSeconds =
        DateTime.now().difference(startTime).inMilliseconds / 1000.0;
    if (durationSeconds < 0.01) return 0.0;

    final actualBytes = response.data?.length ?? 0;
    return (actualBytes * 8) / durationSeconds / 1000000;
  }

  int _jitter() {
    if (latencies.length < 2) return 0;
    int sum = 0;
    for (int i = 1; i < latencies.length; i++) {
      sum += (latencies[i] - latencies[i - 1]).abs();
    }
    return (sum / (latencies.length - 1)).round();
  }

  double _calculatePercentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final index = (percentile * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }
}
