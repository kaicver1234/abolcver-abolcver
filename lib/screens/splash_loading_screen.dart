import 'package:flutter/material.dart';

class SplashLoadingScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashLoadingScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _progress;

  static const Color _cyan = Color(0xFF00D9FF);
  static const Color _green = Color(0xFF00FFA3);
  static const Color _darkBg = Color(0xFF0A0E1A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.95, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _navigateToNext();
    });
  }

  void _navigateToNext() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _darkBg,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 28),
                            _buildAppName(),
                            const SizedBox(height: 8),
                            _buildTagline(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottom(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF111827),
        border: Border.all(
          color: _cyan.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cyan, _green],
        ).createShader(bounds),
        child: const Icon(
          Icons.security_rounded,
          size: 42,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_green, _cyan],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: const Text(
        'TIKSAR VPN',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 3,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'Fast · Secure · Free',
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.35),
        letterSpacing: 2,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 52, left: 48, right: 48),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress.value,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(_cyan, _green, _progress.value)!,
              ),
              minHeight: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'v1.1.5',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.2),
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
