// Widget tests for the shared WaveLoading animation.
// No network needed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiksarvpn/widgets/wave_loading.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('default WaveLoading builds and animates without errors',
      (tester) async {
    await tester.pumpWidget(_host(const WaveLoading()));
    expect(find.byType(WaveLoading), findsOneWidget);

    // Advance the looping animation through a full cycle in steps; any
    // RenderFlex overflow or ticker error would throw here.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('WaveLoading.small fits inside a tight clipped box',
      (tester) async {
    // Reproduces the in-button usage: a small clipping container.
    await tester.pumpWidget(_host(
      ClipRect(
        child: SizedBox(
          width: 20,
          height: 20,
          child: Center(child: const WaveLoading.small()),
        ),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.byType(WaveLoading), findsOneWidget);
  });

  testWidgets('custom bar count renders the requested number of bars',
      (tester) async {
    await tester.pumpWidget(_host(const WaveLoading(barCount: 3)));
    await tester.pump(const Duration(milliseconds: 50));
    // Each bar is a Container; assert at least the 3 bars exist.
    expect(find.byType(Container), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposes cleanly (no leaked ticker)', (tester) async {
    await tester.pumpWidget(_host(const WaveLoading()));
    await tester.pump(const Duration(milliseconds: 100));
    // Replacing the tree disposes the WaveLoading state/controller.
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });
}
