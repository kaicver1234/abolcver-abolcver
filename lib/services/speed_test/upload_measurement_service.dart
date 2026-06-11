import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'speed_test_api.dart';
import 'speed_measurement_config.dart';

/// Uploads a series of fixed-size random payloads and reports throughput.
///
/// Reliability comes from sending a *known* Content-Length body: a stream of
/// random chunks totalling exactly `bytes`. The server accepts it as a normal
/// fixed-size upload, and `onSendProgress` lets us track live speed. Speed is
/// total bits / wall-clock duration; the reported figure is the 90th
/// percentile across samples.
class UploadMeasurementService {
  final SpeedTestApi api;
  final String measurementId;
  final bool Function() isCanceledCheck;
  final void Function(double speed) onSpeedUpdate;
  final void Function(
          double percentileSpeed, double avgSpeed, int jitter, double packetLoss)
      onMetricsUpdate;

  final List<double> uploadSpeeds = [];
  final List<int> latencies;
  final List<Map<String, dynamic>> measurements;

  UploadMeasurementService({
    required this.api,
    required this.measurementId,
    required this.isCanceledCheck,
    required this.onSpeedUpdate,
    required this.onMetricsUpdate,
    required this.latencies,
    required this.measurements,
  });

  Future<void> runMeasurement(Map<String, dynamic> config) async {
    final bytes = config['bytes'] as int;
    final count = config['count'] as int;
    final sizeLabel = SpeedMeasurementConfig.formatBytes(bytes);
    int consecutiveFailures = 0;

    for (int i = 0; i < count; i++) {
      if (isCanceledCheck()) {
        debugPrint('🛑 Upload measurement canceled');
        return;
      }

      try {
        final speed = await _measureSpeed(bytes);
        if (speed > 0 && !isCanceledCheck()) {
          uploadSpeeds.add(speed);
          consecutiveFailures = 0;

          final percentileSpeed = _calculatePercentile(uploadSpeeds, 0.9);
          final avgSpeed =
              uploadSpeeds.reduce((a, b) => a + b) / uploadSpeeds.length;

          onMetricsUpdate(percentileSpeed, avgSpeed, _jitter(), _packetLoss());

          debugPrint(
              '   📤 Upload ${i + 1}/$count ($sizeLabel): ${speed.toStringAsFixed(2)} Mbps (p90: ${percentileSpeed.toStringAsFixed(2)})');
        }
      } catch (e) {
        consecutiveFailures++;
        debugPrint('   ❌ Upload measurement ${i + 1} failed: $e');
        if (consecutiveFailures >= SpeedMeasurementConfig.maxConsecutiveFailures) {
          throw Exception('Network connection lost during upload test.');
        }
      }

      await Future.delayed(SpeedMeasurementConfig.measurementDelay);
    }
  }

  Future<double> _measureSpeed(int bytes) async {
    if (isCanceledCheck()) return 0.0;

    final startTime = DateTime.now();
    DateTime? lastUpdateTime;
    final completer = Completer<double>();

    final streamController = StreamController<List<int>>();
    int sentBytes = 0;

    // Feed random chunks into the request body until we've queued `bytes`.
    Future.microtask(() async {
      final random = Random();
      while (sentBytes < bytes) {
        if (streamController.isClosed) break;
        final remaining = bytes - sentBytes;
        final size = min(SpeedMeasurementConfig.chunkSize, remaining);
        final chunk = List<int>.generate(size, (_) => random.nextInt(256));
        streamController.add(chunk);
        sentBytes += size;
        await Future.delayed(const Duration(microseconds: 1));
      }
      await streamController.close();
    });

    api
        .uploadTest(
      streamController.stream,
      contentLength: bytes,
      measurementId: measurementId,
      during: 'upload',
      onSendProgress: (sent, total) {
        final now = DateTime.now();
        final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
        if (!isCanceledCheck() &&
            elapsed > 0.05 &&
            (lastUpdateTime == null ||
                now.difference(lastUpdateTime!).inMilliseconds > 100)) {
          final mbps = (sent * 8) / elapsed / 1000000;
          onSpeedUpdate(SpeedMeasurementConfig.roundSpeed(mbps));
          lastUpdateTime = now;
        }
      },
    )
        .then((_) {
      if (isCanceledCheck()) {
        completer.complete(0.0);
        return;
      }
      final durationSeconds =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      if (durationSeconds < 0.01) {
        completer.complete(0.0);
        return;
      }
      completer.complete((bytes * 8) / durationSeconds / 1000000);
    }).catchError((e) {
      debugPrint('   ❌ Upload measurement error: $e');
      if (!streamController.isClosed) streamController.close();
      completer.completeError(Exception('Upload failed: $e'));
    });

    return completer.future;
  }

  int _jitter() {
    if (latencies.length < 2) return 0;
    int sum = 0;
    for (int i = 1; i < latencies.length; i++) {
      sum += (latencies[i] - latencies[i - 1]).abs();
    }
    return (sum / (latencies.length - 1)).round();
  }

  double _packetLoss() {
    if (latencies.length <= 10) return 0.0;
    final expectedPackets = measurements
        .where((m) => m['type'] == 'latency')
        .fold<int>(0, (sum, m) => sum + (m['numPackets'] as int));
    if (expectedPackets == 0) return 0.0;
    return ((expectedPackets - latencies.length) / expectedPackets * 100)
        .clamp(0.0, 100.0);
  }

  double _calculatePercentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final index = (percentile * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }
}
