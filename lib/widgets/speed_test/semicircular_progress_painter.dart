import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

enum ProgressStep { upload, download }

class SemicircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Animation<double>? animation;
  final ProgressStep showStep;

  SemicircularProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 12.0,
    this.animation,
    this.showStep = ProgressStep.upload,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;

    const startAngle = math.pi * 0.85;
    const sweepAngle = math.pi * 1.3;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    final animatedProgress = animation?.value ?? progress;

    if (animatedProgress > 0) {
      // Draw shadow
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 17);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * animatedProgress,
        false,
        shadowPaint,
      );

      // Draw multiple layers for glow effect
      const layers = 5;
      const layerSpacing = 1.5;
      const totalOffset = (layers - 1) * layerSpacing;
      const middleLayerOffset = totalOffset / 2;

      for (int i = 0; i < layers; i++) {
        final layerRadius = radius + middleLayerOffset - (i * layerSpacing);
        final gradient = _createGradient(color, center, layerRadius, animatedProgress);

        final progressPaint = Paint()
          ..shader = gradient
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: layerRadius),
          startAngle,
          sweepAngle * animatedProgress,
          false,
          progressPaint,
        );
      }

      _drawProgressIndicator(canvas, center, radius, animatedProgress, color);
    }
  }

  Shader _createGradient(Color baseColor, Offset center, double radius, double progress) {
    List<Color> gradientColors;

    if (baseColor == AppColors.downloadColor || baseColor == Colors.green) {
      gradientColors = [
        AppColors.downloadColor,
        AppColors.downloadColor,
        AppColors.downloadColor,
      ];
    } else if (baseColor == AppColors.uploadColor || baseColor == Colors.blue) {
      gradientColors = [
        AppColors.uploadColor,
        AppColors.uploadColor,
        AppColors.uploadColor,
      ];
    } else {
      gradientColors = [baseColor, baseColor, baseColor];
    }

    const startAngle = math.pi * 0.85;
    const sweepAngle = math.pi * 1.3;

    return SweepGradient(
      colors: gradientColors,
      startAngle: startAngle,
      endAngle: startAngle + (sweepAngle * progress),
    ).createShader(Rect.fromCircle(center: center, radius: radius));
  }

  void _drawProgressIndicator(
      Canvas canvas, Offset center, double radius, double progress, Color color) {
    const startAngle = math.pi * 0.85;
    const sweepAngle = math.pi * 1.3;
    final angle = startAngle + (sweepAngle * progress);
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);
    final dotPosition = Offset(dotX, dotY);

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(dotPosition, 4.0, glowPaint);

    // Dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dotPosition, 4.0, dotPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(dotPosition.dx - 1, dotPosition.dy - 1),
      2.0,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(SemicircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
