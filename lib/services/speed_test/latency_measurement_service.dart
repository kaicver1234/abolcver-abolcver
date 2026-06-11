import 'package:flutter/foundation.dart';
import 'speed_test_api.dart';
import 'speed_measurement_config.dart';

/// Measures round-trip latency with a burst of zero-byte requests, tracking
/// average latency and jitter (mean absolute consecutive difference).
class LatencyMeasurementService {
  final SpeedTestApi api;
  final String measurementId;
  final bool Function() isCanceledCheck;
  final void Function(int ping, int latency, int jitter) onMetricsUpdate;

  final List<int> latencies = [];

  LatencyMeasurementService({
    required this.api,
    required this.measurementId,
    required this.isCanceledCheck,
    required this.onMetricsUpdate,
  });

  Future<void> runMeasurement(Map<String, dynamic> config) async {
    final numPackets = config['numPackets'] as int;
    int consecutiveFailures = 0;

    for (int i = 0; i < numPackets; i++) {
      if (isCanceledCheck()) {
        debugPrint('🛑 Latency measurement canceled');
        return;
      }

      try {
        final startTime = DateTime.now();
        await api.latencyTest(bytes: 0, measurementId: measurementId);
        final latency = DateTime.now().difference(startTime).inMilliseconds;

        if (isCanceledCheck()) return;

        latencies.add(latency);
        consecutiveFailures = 0;

        final avgLatency =
            (latencies.reduce((a, b) => a + b) / latencies.length).round();

        onMetricsUpdate(latency, avgLatency, _jitter());

        debugPrint(
            '   📡 Latency ${i + 1}/$numPackets: ${latency}ms (Avg: ${avgLatency}ms, Jitter: ${_jitter()}ms)');
      } catch (e) {
        consecutiveFailures++;
        debugPrint('   ❌ Latency measurement ${i + 1} failed: $e');
        if (consecutiveFailures >= SpeedMeasurementConfig.maxConsecutiveFailures) {
          throw Exception(
              'Network connection failed. Please check your internet connection.');
        }
      }

      await Future.delayed(SpeedMeasurementConfig.latencyDelay);
    }

    if (latencies.isEmpty) {
      throw Exception(
          'Failed to measure latency. Please check your internet connection.');
    }
  }

  int _jitter() {
    if (latencies.length < 2) return 0;
    int sum = 0;
    for (int i = 1; i < latencies.length; i++) {
      sum += (latencies[i] - latencies[i - 1]).abs();
    }
    return (sum / (latencies.length - 1)).round();
  }
}
