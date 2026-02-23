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
            systemNavigationBarColor: const Color(0xFF000000),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: child, // Removed all glows for pure black background
          ),
        );
      },
    );
  }
}
