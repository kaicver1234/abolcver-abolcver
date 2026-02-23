import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Modern glassmorphism background with animated gradient orbs
class CyberGlowBackground extends StatelessWidget {
  final Widget child;
  final bool showBottomGlow;
  final bool enableBlur;

  const CyberGlowBackground({
    super.key,
    required this.child,
    this.showBottomGlow = true,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: const Color(0xFF0B0D1A),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Top-left purple/blue orb
                Positioned(
                  top: -120,
                  left: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                          const Color(0xFF6C5CE7).withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top-right cyan orb
                Positioned(
                  top: -60,
                  right: -100,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00D9FF).withValues(alpha: 0.08),
                          const Color(0xFF00D9FF).withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Bottom-center green glow
                Positioned(
                  bottom: -140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 400,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00FFA3).withValues(alpha: 0.06),
                            const Color(0xFF00D9FF).withValues(alpha: 0.03),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}
