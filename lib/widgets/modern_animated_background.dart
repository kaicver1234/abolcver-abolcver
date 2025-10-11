import 'package:flutter/material.dart';

/// Ultra-lightweight background with no animations for maximum performance
/// Simple gradient background that uses minimal resources
class ModernAnimatedBackground extends StatelessWidget {
  final Widget child;
  final bool isConnected;
  
  const ModernAnimatedBackground({
    super.key,
    required this.child,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate dark
            Color(0xFF1E293B), // Slate medium
            Color(0xFF0F172A), // Slate dark
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle grid pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// Simple grid pattern painter (no animation, very lightweight)
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 50.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Legacy code below - kept for potential future use but not active
/*
class MeshBackgroundPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final bool isConnected;

  MeshBackgroundPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.isConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw animated gradient orbs
    _drawGradientOrb(
      canvas,
      size,
      Offset(
        size.width * 0.3 + math.cos(animation1) * 50,
        size.height * 0.2 + math.sin(animation1) * 50,
      ),
      150,
      isConnected ? const Color(0xFF00D4FF) : const Color(0xFF6C63FF),
      0.15,
    );

    _drawGradientOrb(
      canvas,
      size,
      Offset(
        size.width * 0.7 + math.sin(animation2) * 60,
        size.height * 0.5 + math.cos(animation2) * 60,
      ),
      200,
      isConnected ? const Color(0xFF00FFB3) : const Color(0xFFFF6B9D),
      0.12,
    );

    _drawGradientOrb(
      canvas,
      size,
      Offset(
        size.width * 0.5 + math.cos(animation3) * 40,
        size.height * 0.8 + math.sin(animation3) * 40,
      ),
      180,
      isConnected ? const Color(0xFF7FFF00) : const Color(0xFFFECA57),
      0.10,
    );

    // Geometric patterns disabled for performance
    // _drawGeometricPattern(canvas, size);
    
    // Draw floating particles
    _drawFloatingParticles(canvas, size);
  }

  void _drawGradientOrb(Canvas canvas, Size size, Offset center, 
      double radius, Color color, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.5),
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  void _drawGeometricPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isConnected ? const Color(0xFF00D4FF) : const Color(0xFF6C63FF))
          .withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw hexagon grid
    const hexSize = 60.0;
    for (double y = 0; y < size.height + hexSize; y += hexSize * 1.5) {
      for (double x = 0; x < size.width + hexSize; x += hexSize * 2) {
        final offset = (y % (hexSize * 3) == 0) ? 0.0 : hexSize;
        final center = Offset(x + offset, y);
        
        // Animate hexagon size based on distance from center
        final distance = (center - Offset(size.width / 2, size.height / 2)).distance;
        final scale = 1.0 + 0.1 * math.sin(animation1 + distance * 0.01);
        
        _drawHexagon(canvas, center, hexSize * 0.5 * scale, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i + animation1 * 0.1;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = (isConnected ? const Color(0xFF00FFB3) : const Color(0xFFFF6B9D))
          .withOpacity(0.3);

    final random = math.Random(42); // Fixed seed for consistent particles
    // Reduced particle count for better performance
    for (int i = 0; i < 10; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 0.5 + 0.5;
      final yOffset = ((animation1 * speed * 100) % size.height);
      final y = (baseY - yOffset) % size.height;
      
      final particleSize = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(MeshBackgroundPainter oldDelegate) {
    // Only repaint if animation values changed significantly
    return (animation1 - oldDelegate.animation1).abs() > 0.01 ||
           isConnected != oldDelegate.isConnected;
  }
}

// Animated gradient wave widget for additional effects
class AnimatedWave extends StatelessWidget {
  final double height;
  final Color color;
  final Duration duration;
  
  const AnimatedWave({
    super.key,
    this.height = 100,
    this.color = const Color(0xFF00D4FF),
    this.duration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(MediaQuery.of(context).size.width, height),
          painter: WavePainter(
            waveAnimation: value,
            color: color,
          ),
        );
      },
      onEnd: () {
        // Loop animation
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double waveAnimation;
  final Color color;

  WavePainter({
    required this.waveAnimation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 2 * math.pi) +
                  (waveAnimation * 2 * math.pi)) *
              size.height * 0.2;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    // Only repaint if animation value changed
    return (waveAnimation - oldDelegate.waveAnimation).abs() > 0.01;
  }
}
*/
