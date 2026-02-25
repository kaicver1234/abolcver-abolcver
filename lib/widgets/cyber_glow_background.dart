import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF000000),
      ),
      child: child,
    );
  }
}
