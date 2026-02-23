import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Modern 3D connection button with advanced animations - Minimalist White Theme
class ModernConnectionButton extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback? onTap;
  final double size;

  const ModernConnectionButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    this.onTap,
    this.size = 180,
  });

  @override
  State<ModernConnectionButton> createState() => _ModernConnectionButtonState();
}

class _ModernConnectionButtonState extends State<ModernConnectionButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    if (widget.isConnecting) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    } else if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ModernConnectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isConnecting && !oldWidget.isConnecting) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    } else if (!widget.isConnecting && oldWidget.isConnecting) {
      _pulseController.stop();
      _rotationController.stop();
    }
    
    if (widget.isConnected && !oldWidget.isConnected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isConnected && oldWidget.isConnected) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor;
    final IconData icon;
    
    if (widget.isConnecting) {
      primaryColor = Colors.white;
      icon = Icons.sync;
    } else if (widget.isConnected) {
      primaryColor = Colors.white;
      icon = Icons.power_settings_new_rounded;
    } else {
      primaryColor = Colors.white.withValues(alpha: 0.15);
      icon = Icons.power_settings_new_rounded;
    }
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              if (widget.isConnected || widget.isConnecting) ...[
                _buildGlowRing(
                  size: widget.size * 1.4 * _pulseAnimation.value,
                  color: Colors.white,
                  opacity: 0.08,
                ),
                _buildGlowRing(
                  size: widget.size * 1.25 * _pulseAnimation.value,
                  color: Colors.white,
                  opacity: 0.12,
                ),
              ],
              
              // Rotating ring for connecting state
              if (widget.isConnecting)
                RotationTransition(
                  turns: _rotationController,
                  child: _buildRotatingRing(widget.size * 1.15, Colors.white),
                ),
              
              // Main button
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    if (widget.isConnected || widget.isConnecting) ...[
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 60,
                        spreadRadius: 0,
                      ),
                    ] else ...[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isConnected || widget.isConnecting
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: widget.isConnecting
                        ? RotationTransition(
                            turns: _rotationController,
                            child: Icon(
                              icon,
                              size: widget.size * 0.35,
                              color: Colors.black.withValues(alpha: 0.8),
                            ),
                          )
                        : Icon(
                            icon,
                            size: widget.size * 0.35,
                            color: widget.isConnected 
                                ? Colors.black.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                  ),
                ),
              ),
              
              // Inner highlight
              if (widget.isConnected || widget.isConnecting)
                Positioned(
                  top: widget.size * 0.15,
                  child: Container(
                    width: widget.size * 0.4,
                    height: widget.size * 0.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlowRing(
      {required double size, required Color color, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildRotatingRing(double size, Color color) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RotatingRingPainter(color: color),
    );
  }
}

class _RotatingRingPainter extends CustomPainter {
  final Color color;

  _RotatingRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw arc segments
    for (int i = 0; i < 4; i++) {
      final startAngle = (i * math.pi / 2) + (math.pi / 8);
      final sweepAngle = math.pi / 4;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
