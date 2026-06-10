import 'dart:io';
import 'package:image/image.dart' as img;

/// Wraps assets/images/apk.png in transparent padding so the Android adaptive
/// icon mask stops zooming/cropping it. The visible logo ends up at ~70% of the
/// canvas, which fits inside the adaptive "safe zone" (the central ~66dp of
/// 108dp) instead of being blown up to fill the whole tile.
void main() {
  const src = 'assets/images/apk.png';
  const dst = 'assets/images/apk_foreground.png';

  // Fraction of the canvas the logo should occupy (rest is transparent margin).
  const logoFraction = 0.70;

  final bytes = File(src).readAsBytesSync();
  final logo = img.decodeImage(bytes);
  if (logo == null) {
    stderr.writeln('Could not decode $src');
    exit(1);
  }

  // Canvas sized so the logo (kept at its native size) occupies logoFraction.
  final longest = logo.width > logo.height ? logo.width : logo.height;
  final canvasSize = (longest / logoFraction).round();

  final canvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  // Fully transparent background.
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final dx = ((canvasSize - logo.width) / 2).round();
  final dy = ((canvasSize - logo.height) / 2).round();
  img.compositeImage(canvas, logo, dstX: dx, dstY: dy);

  File(dst).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Wrote $dst (${canvasSize}x$canvasSize, logo at ${(logoFraction * 100).round()}%)');
}
