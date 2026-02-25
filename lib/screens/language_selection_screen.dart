import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../models/app_language.dart';
import 'privacy_welcome_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  AppLanguage? _selectedLanguage;
  bool _isChangingLanguage = false;

  late AnimationController _entranceController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _headerOpacity;
  late Animation<double> _headerSlide;
  late Animation<double> _cardsOpacity;
  late Animation<double> _cardsSlide;
  late Animation<double> _pulseAnim;

  static const Color _cyan = Color(0xFF00D9FF);
  static const Color _green = Color(0xFF00FFA3);
  static const Color _darkBg = Color(0xFF050A0F);

  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      language: AppLanguage(name: 'English', code: 'en', flag: '🇺🇸', direction: 'ltr'),
      flag: '🇺🇸',
      displayName: 'English',
      subtitle: 'Continue in English',
      accentColor: Color(0xFF00D9FF),
      glowColor: Color(0xFF0A3D52),
    ),
    _LanguageOption(
      language: AppLanguage(name: 'فارسی', code: 'fa', flag: '🇮🇷', direction: 'rtl'),
      flag: '🇮🇷',
      displayName: 'فارسی',
      subtitle: 'ادامه به زبان فارسی',
      accentColor: Color(0xFF00FFA3),
      glowColor: Color(0xFF0A3D2A),
    ),
  ];

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(7);

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _setupAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        setState(() => _selectedLanguage = lang);
      }
    });
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.0 + 0.5,
        opacity: _random.nextDouble() * 0.3 + 0.05,
        speed: _random.nextDouble() * 0.2 + 0.05,
        phase: _random.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _setupAnimations() {
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<double>(begin: -24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _cardsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _cardsSlide = Tween<double>(begin: 32.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(AppLanguage language) async {
    if (_isChangingLanguage || !mounted) return;
    setState(() {
      _selectedLanguage = language;
      _isChangingLanguage = true;
    });

    final lp = Provider.of<LanguageProvider>(context, listen: false);
    await lp.changeLanguage(language);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);

    if (mounted) {
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PrivacyWelcomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
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
            _buildContent(size),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.1,
          left: size.width * 0.5 - 160,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _cyan.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.08,
          left: size.width * 0.5 - 160,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 2.0 - _pulseAnim.value,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _green.withValues(alpha: 0.06),
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

  Widget _buildContent(Size size) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.08),
            _buildHeader(),
            SizedBox(height: size.height * 0.06),
            Expanded(child: _buildLanguageCards()),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, __) {
        return Opacity(
          opacity: _headerOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _headerSlide.value),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
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
                          color: _cyan.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_cyan, _green],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.language_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_green, _cyan],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Choose Language',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'زبان خود را انتخاب کنید',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageCards() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, __) {
        return Opacity(
          opacity: _cardsOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _cardsSlide.value),
            child: Column(
              children: _languages.asMap().entries.map((entry) {
                final i = entry.key;
                final opt = entry.value;
                final isSelected = _selectedLanguage == opt.language;
                return Padding(
                  padding: EdgeInsets.only(bottom: i < _languages.length - 1 ? 16 : 0),
                  child: _LanguageCard(
                    key: ValueKey(opt.language.code),
                    option: opt,
                    isSelected: isSelected,
                    isLoading: _isChangingLanguage && isSelected,
                    onTap: () => _selectLanguage(opt.language),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption {
  final AppLanguage language;
  final String flag;
  final String displayName;
  final String subtitle;
  final Color accentColor;
  final Color glowColor;

  const _LanguageOption({
    required this.language,
    required this.flag,
    required this.displayName,
    required this.subtitle,
    required this.accentColor,
    required this.glowColor,
  });
}

class _LanguageCard extends StatefulWidget {
  final _LanguageOption option;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _LanguageCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opt = widget.option;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected ? opt.glowColor : const Color(0xFF0A1520),
            border: Border.all(
              color: isSelected
                  ? opt.accentColor.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.07),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: opt.accentColor.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Row(
            children: [
              Text(opt.flag, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? opt.accentColor : Colors.white,
                        letterSpacing: -0.3,
                      ),
                      child: Text(opt.displayName),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: opt.accentColor,
                          strokeWidth: 2,
                        ),
                      )
                    : isSelected
                        ? Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: opt.accentColor,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 16,
                            ),
                          )
                        : Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
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

      final dy = (p.y + progress * p.speed * 0.06) % 1.0;

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
