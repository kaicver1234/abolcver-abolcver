// Live integration test for SpeedTestProvider.
//
// This talks to the real Cloudflare speed-test endpoints, so it needs an
// internet connection. It verifies that:
//   1. download and upload both produce a sane (> 0) result, and
//   2. the UPLOAD live readout keeps moving and never freezes — the original
//      bug was that upload jumped to a value, stalled, then dropped to zero.
//
// Run with:  flutter test test/speed_test_provider_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiksarvpn/models/speed_test_state.dart';
import 'package:tiksarvpn/providers/speed_test_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_test installs an HttpOverrides that blocks real network calls
  // (every request returns 400). Disable it so this integration test can reach
  // the real Cloudflare endpoints.
  HttpOverrides.global = null;

  test('full speed test runs without freezing (live network)', () async {
    final provider = SpeedTestProvider();

    // Timeline of live readings, per phase.
    final downloadSamples = <double>[];
    final uploadSamples = <double>[];

    final stopwatch = Stopwatch()..start();
    void listener() {
      final s = provider.state;
      final speed = s.currentSpeed;
      if (s.step == SpeedTestStep.download) {
        downloadSamples.add(speed);
      } else if (s.step == SpeedTestStep.upload) {
        uploadSamples.add(speed);
      }
    }

    provider.addListener(listener);

    // Kick off the test (don't await — we poll for completion below).
    final running = provider.startTest();

    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!provider.state.testCompleted && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await running;

    stopwatch.stop();
    provider.removeListener(listener);

    final r = provider.state.result;

    // ── Helpers ──────────────────────────────────────────────────────────────
    int nonZero(List<double> xs) => xs.where((v) => v > 0).length;
    int distinctNonZero(List<double> xs) =>
        xs.where((v) => v > 0).toSet().length;
    double maxOf(List<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a > b ? a : b);

    // ── Report ───────────────────────────────────────────────────────────────
    // ignore: avoid_print
    print('──────── Speed test result ────────');
    // ignore: avoid_print
    print('elapsed         : ${stopwatch.elapsed.inSeconds}s');
    // ignore: avoid_print
    print('ping / jitter   : ${r.ping} ms / ${r.jitter} ms');
    // ignore: avoid_print
    print('download        : ${r.downloadSpeed.toStringAsFixed(2)} Mbps');
    // ignore: avoid_print
    print('upload          : ${r.uploadSpeed.toStringAsFixed(2)} Mbps');
    // ignore: avoid_print
    print('download live   : ${downloadSamples.length} samples, '
        '${distinctNonZero(downloadSamples)} distinct non-zero, '
        'peak ${maxOf(downloadSamples).toStringAsFixed(1)}');
    // ignore: avoid_print
    print('upload live     : ${uploadSamples.length} samples, '
        '${distinctNonZero(uploadSamples)} distinct non-zero, '
        'peak ${maxOf(uploadSamples).toStringAsFixed(1)}');
    // ignore: avoid_print
    print('upload timeline : ${uploadSamples.map((v) => v.toStringAsFixed(0)).join(' ')}');
    // ignore: avoid_print
    print('───────────────────────────────────');

    // ── Assertions ─────────────────────────────────────────────────────────
    expect(r.downloadSpeed, greaterThan(0),
        reason: 'download speed must be measured');
    expect(r.uploadSpeed, greaterThan(0),
        reason: 'upload speed must be measured');

    // The freeze bug: upload would produce a single jump then stall.
    // A healthy run yields many distinct live readings during upload.
    expect(nonZero(uploadSamples), greaterThan(5),
        reason: 'upload live readout should keep updating, not freeze');
    expect(distinctNonZero(uploadSamples), greaterThan(3),
        reason: 'upload live readout should vary over time, not stick on one value');
  }, timeout: const Timeout(Duration(seconds: 90)));
}
