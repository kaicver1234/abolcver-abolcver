// Live integration test for the Host Checker reachability logic.
//
// It needs an internet connection. It reproduces the exact check the screen now
// performs (a TCP handshake) and proves it reaches heavy hosts like YouTube
// quickly — the scenario that used to time out with the old full `http.get`.
//
// Run with:  flutter test test/host_checker_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _connectTimeout = Duration(seconds: 8);

// Mirror of HostCheckerScreen._tcpConnect (kept in sync for testing).
Future<int> tcpConnect(String host, int port) async {
  final sw = Stopwatch()..start();
  final socket = await Socket.connect(host, port, timeout: _connectTimeout);
  sw.stop();
  socket.destroy();
  return sw.elapsedMilliseconds;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // allow real network in flutter_test

  test('reachable hosts connect fast over TCP (incl. YouTube)', () async {
    for (final host in ['youtube.com', 'google.com', 'cloudflare.com']) {
      final ms = await tcpConnect(host, 443);
      // ignore: avoid_print
      print('$host -> ONLINE  ${ms}ms');
      expect(ms, lessThan(_connectTimeout.inMilliseconds),
          reason: '$host should be reachable well within the timeout');
    }
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('unknown host resolves quickly and never hangs', () async {
    // On a normal network this throws SocketException (Failed host lookup),
    // which the screen maps to "Host not found". Some networks (and this CI
    // sandbox) hijack NXDOMAIN and connect to a captive IP instead — so we only
    // assert the check is BOUNDED (never hangs), regardless of DNS behaviour.
    final sw = Stopwatch()..start();
    Object? thrown;
    try {
      await tcpConnect('this-host-does-not-exist-9f2a1c.invalid', 443);
    } catch (e) {
      thrown = e;
    }
    sw.stop();
    // ignore: avoid_print
    print('bogus host -> ${thrown ?? 'connected (DNS hijacked)'} '
        'in ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsed, lessThan(_connectTimeout + const Duration(seconds: 2)),
        reason: 'check must be bounded by the connect timeout, not hang');
    if (thrown != null) expect(thrown, isA<SocketException>());
  }, timeout: const Timeout(Duration(seconds: 30)));

  // Demonstrates WHY the old approach was wrong: a full GET of youtube.com is
  // slow/heavy (large body + redirects). We don't assert it fails (network
  // dependent), we just measure it next to the TCP handshake for comparison.
  test('comparison: old full http.get is much heavier than a TCP handshake',
      () async {
    final tcpMs = await tcpConnect('youtube.com', 443);

    int? getMs;
    String getOutcome;
    final sw = Stopwatch()..start();
    try {
      final resp = await http
          .get(Uri.parse('https://youtube.com'))
          .timeout(const Duration(seconds: 10));
      sw.stop();
      getMs = sw.elapsedMilliseconds;
      getOutcome = 'status ${resp.statusCode}, ${resp.bodyBytes.length} bytes';
    } on TimeoutException {
      sw.stop();
      getOutcome = 'TIMEOUT after ${sw.elapsedMilliseconds}ms';
    } catch (e) {
      sw.stop();
      getOutcome = 'error after ${sw.elapsedMilliseconds}ms: $e';
    }

    // ignore: avoid_print
    print('TCP handshake : ${tcpMs}ms');
    // ignore: avoid_print
    print('Full http.get : ${getMs ?? '-'}  ($getOutcome)');

    expect(tcpMs, lessThan(_connectTimeout.inMilliseconds));
  }, timeout: const Timeout(Duration(seconds: 40)));
}
