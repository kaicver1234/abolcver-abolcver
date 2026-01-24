import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cyber Glow Background - V7 Final Mix Style
/// Matches the HTML background-v7-final-mix.html exactly
/// Three layers: center dark, top aurora, bottom seamless glow
class CyberGlowBackground extends StatelessWidget {
  final Widget child;
  final bool showBottomGlow;

  const CyberGlowBackground({
    super.key,
    required this.child,
    this.showBottomGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0a0a0a),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a0a),
        body: Stack(
          children: [
            // Layer 1: Base dark background
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF0a0a0a),
            ),
            
            // Layer 2: Center dark radial gradient
            // CSS: radial-gradient(ellipse at 50% 40%, #0c0c12 0%, #0a0a0a 70%)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.2), // 50% 40%
                    radius: 1.5,
                    colors: [
                      Color(0xFF0c0c12),
                      Color(0xFF0a0a0a),
                    ],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
            
            // Layer 3: Top Aurora effect with blur
            // CSS: radial-gradient(ellipse 80% 50% at 50% 30%, rgba(99, 102, 241, 0.08) 0%, transparent 60%)
            // with filter: blur(30px)
            Positioned(
              top: -150,
              left: 0,
              right: 0,
              child: _buildTopAurora(),
            ),
            
            // Layer 4: Bottom glow - seamless blend (three sub-layers)
            if (showBottomGlow)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomGlow(context),
              ),
            
            // Content
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAurora() {
    // Matches HTML: height: 450px, radial-gradient with blur(30px)
    return Container(
      height: 450,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.4), // at 50% 30%
          radius: 0.9,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.08), // rgba(99, 102, 241, 0.08)
            Colors.transparent,
          ],
          stops: const [0.0, 0.6],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildBottomGlow(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomHeight = screenHeight * 0.45; // 45% of screen height
    
    return SizedBox(
      height: bottomHeight,
      child: Stack(
        children: [
          // Sub-layer 1: Linear gradient fade
          // CSS: linear-gradient(180deg, transparent 0%, rgba(16, 185, 129, 0.03) 60%, rgba(16, 185, 129, 0.06) 100%)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF10B981).withValues(alpha: 0.03),
                    const Color(0xFF10B981).withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // Sub-layer 2: Left radial glow (green)
          // CSS: radial-gradient(ellipse at 30% 100%, rgba(16, 185, 129, 0.08) 0%, transparent 45%)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, 1.0), // at 30% 100%
                  radius: 0.7,
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
          ),
          
          // Sub-layer 3: Right radial glow (cyan)
          // CSS: radial-gradient(ellipse at 70% 100%, rgba(6, 182, 212, 0.06) 0%, transparent 45%)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.4, 1.0), // at 70% 100%
                  radius: 0.7,
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
