import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _shieldController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _shieldScale;
  late Animation<double> _shieldOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _progressAnim;
  late Animation<double> _pulseAnim;

  static const Color _cyan = Color(0xFF00D9FF);
  static const Color _green = Color(0xFF00FFA3);
  static const Color _darkBg = Color(0xFF050A0F);

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _setupAnimations();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.5 + 0.5,
        opacity: _random.nextDouble() * 0.4 + 0.1,
        speed: _random.nextDouble() * 0.3 + 0.1,
        phase: _random.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _setupAnimations() {
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shieldScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.elasticOut),
    );
    _shieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shieldController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _startSequence() {
    _bgController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _shieldController.forward();
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _textController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _progressController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
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
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _shieldController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _darkBg,
        body: Stack(
          children: [
            _buildBackground(size),
            _buildParticles(size),
            _buildGlowOrbs(size),
            _buildContent(size),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        return Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                const Color(0xFF0A1628).withValues(alpha: _bgController.value),
                _darkBg,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (_, __) {
        return CustomPaint(
          size: size,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
            cyan: _cyan,
            green: _green,
          ),
        );
      },
    );
  }

  Widget _buildGlowOrbs(Size size) {
    return Stack(
      children: [
        Positioned(
          top: size.height * 0.12,
          right: -60,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _cyan.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.15,
          left: -80,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 2.0 - _pulseAnim.value,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _green.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(Size size) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildShieldLogo(),
                  const SizedBox(height: 32),
                  _buildAppName(),
                  const SizedBox(height: 10),
                  _buildTagline(),
                ],
              ),
            ),
          ),
          _buildBottomSection(size),
        ],
      ),
    );
  }

  Widget _buildShieldLogo() {
    return AnimatedBuilder(
      animation: _shieldController,
      builder: (_, __) {
        return Opacity(
          opacity: _shieldOpacity.value,
          child: Transform.scale(
            scale: _shieldScale.value,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _cyan.withValues(alpha: 0.15),
                          _green.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0D2137), Color(0xFF081520)],
                      ),
                      border: Border.all(
                        color: _cyan.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: _green.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
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
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (_, __) {
        return Opacity(
          opacity: _textOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _textSlide.value),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_green, _cyan],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'TIKSAR VPN',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (_, __) {
        return Opacity(
          opacity: _taglineOpacity.value,
          child: const Text(
            'Fast · Secure · Free',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B8BA4),
              letterSpacing: 2.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection(Size size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48, left: 48, right: 48),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressController,
            builder: (_, __) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressAnim.value,
                      backgroundColor: const Color(0xFF0D2137),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(_cyan, _green, _progressAnim.value)!,
                      ),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: _progressAnim.value,
                    child: const Text(
                      'v1.1.4',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF3A5568),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color cyan;
  final Color green;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.cyan,
    required this.green,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final twinkle = (math.sin(progress * math.pi * 2 * p.speed + p.phase) + 1) / 2;
      final opacity = p.opacity * (0.3 + twinkle * 0.7);
      final color = i % 2 == 0 ? cyan : green;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final dy = (p.y + progress * p.speed * 0.08) % 1.0;

      canvas.drawCircle(
        Offset(p.x * size.width, dy * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
