import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Cyber Glow Background - Theme-Aware Version
/// High-performance background with minimal widget overhead
/// Three layers: center dark, top aurora, bottom seamless glow
class CyberGlowBackground extends StatelessWidget {
  final Widget child;
  final bool showBottomGlow;
  final bool enableBlur; // Option to enable blur (impacts performance)

  const CyberGlowBackground({
    super.key,
    required this.child,
    this.showBottomGlow = true,
    this.enableBlur = false, // Disabled by default for performance
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colors = themeProvider.colors;
        final themeId = themeProvider.currentTheme.id;
        final baseColor = Color(colors.backgroundColor);
        
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: baseColor,
          ),
          child: Scaffold(
            backgroundColor: baseColor,
            body: Stack(
              children: [
                // Layer 1: Base background (very dark)
                const ColoredBox(
                  color: Color(0xFF050505),
                  child: SizedBox.expand(),
                ),
                
                // Layer 2: Bottom glow (theme-specific gradient from bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomGlow(context, colors, themeId),
                ),
                
                // Layer 3: Center fade (dark gradient to top)
                Positioned.fill(
                  child: _buildCenterFade(),
                ),
                
                // Layer 4: Top dim (solid dark)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopDim(context),
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

  Widget _buildBottomGlow(BuildContext context, colors, String themeId) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomHeight = screenHeight * 0.5;
    
    // Different gradient colors based on theme
    List<Color> gradientColors;
    
    switch (themeId) {
      case 'default': // Dark Red
        gradientColors = const [
          Color.fromRGBO(60, 5, 15, 0.55),
          Color.fromRGBO(70, 8, 18, 0.45),
          Color.fromRGBO(80, 10, 22, 0.36),
          Color.fromRGBO(90, 12, 26, 0.28),
          Color.fromRGBO(100, 14, 30, 0.20),
          Color.fromRGBO(110, 16, 34, 0.12),
          Color.fromRGBO(120, 18, 38, 0.06),
          Color.fromRGBO(130, 20, 42, 0.03),
          Colors.transparent,
        ];
        break;
      case 'ocean': // Dark Blue
        gradientColors = const [
          Color.fromRGBO(5, 15, 60, 0.55),
          Color.fromRGBO(8, 18, 70, 0.45),
          Color.fromRGBO(10, 22, 80, 0.36),
          Color.fromRGBO(12, 26, 90, 0.28),
          Color.fromRGBO(14, 30, 100, 0.20),
          Color.fromRGBO(16, 34, 110, 0.12),
          Color.fromRGBO(18, 38, 120, 0.06),
          Color.fromRGBO(20, 42, 130, 0.03),
          Colors.transparent,
        ];
        break;
      case 'sunset': // Dark Purple
        gradientColors = const [
          Color.fromRGBO(40, 5, 50, 0.55),
          Color.fromRGBO(50, 8, 60, 0.45),
          Color.fromRGBO(60, 10, 70, 0.36),
          Color.fromRGBO(70, 12, 80, 0.28),
          Color.fromRGBO(80, 14, 90, 0.20),
          Color.fromRGBO(90, 16, 100, 0.12),
          Color.fromRGBO(100, 18, 110, 0.06),
          Color.fromRGBO(110, 20, 120, 0.03),
          Colors.transparent,
        ];
        break;
      case 'forest': // Dark Green
        gradientColors = const [
          Color.fromRGBO(5, 60, 15, 0.55),
          Color.fromRGBO(8, 70, 18, 0.45),
          Color.fromRGBO(10, 80, 22, 0.36),
          Color.fromRGBO(12, 90, 26, 0.28),
          Color.fromRGBO(14, 100, 30, 0.20),
          Color.fromRGBO(16, 110, 34, 0.12),
          Color.fromRGBO(18, 120, 38, 0.06),
          Color.fromRGBO(20, 130, 42, 0.03),
          Colors.transparent,
        ];
        break;
      default:
        gradientColors = const [
          Color.fromRGBO(60, 5, 15, 0.55),
          Color.fromRGBO(70, 8, 18, 0.45),
          Color.fromRGBO(80, 10, 22, 0.36),
          Color.fromRGBO(90, 12, 26, 0.28),
          Color.fromRGBO(100, 14, 30, 0.20),
          Color.fromRGBO(110, 16, 34, 0.12),
          Color.fromRGBO(120, 18, 38, 0.06),
          Color.fromRGBO(130, 20, 42, 0.03),
          Colors.transparent,
        ];
    }
    
    return Container(
      height: bottomHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: gradientColors,
          stops: const [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
        ),
      ),
    );
  }

  Widget _buildCenterFade() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Color.fromRGBO(5, 5, 5, 0.4),
            Color.fromRGBO(5, 5, 5, 0.75),
            Color.fromRGBO(5, 5, 5, 0.92),
            Color.fromRGBO(5, 5, 5, 1),
            Color.fromRGBO(5, 5, 5, 1),
          ],
          stops: [0.0, 0.4, 0.5, 0.6, 0.7, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildTopDim(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topHeight = screenHeight * 0.5;
    
    return Container(
      height: topHeight,
      color: const Color(0xFF050505),
    );
  }
}
