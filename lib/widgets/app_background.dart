import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showBackground;
  final bool useSecondaryBackground;

  const AppBackground({
    super.key,
    required this.child,
    this.showBackground = true,
    this.useSecondaryBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return child;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0D1A),
            Color(0xFF0A0C18),
            Color(0xFF060812),
            Color(0xFF0B0D1A),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}
