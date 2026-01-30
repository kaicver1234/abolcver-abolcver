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
  late AnimationController _lettersController;
  late AnimationController _underlineController;
  late AnimationController _taglineController;
  late AnimationController _versionController;
  late AnimationController _flickerController;

  final List<Animation<double>> _letterOpacityAnims = [];
  final List<Animation<double>> _letterFlickerAnims = [];

  static const Color green = Color(0xFF10B981);
  static const Color cyan = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Letters appear animation
    _lettersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Letter timings: T(0.1s), I(0.2s), K(0.3s), S(0.4s), A(0.5s), R(0.6s), V(0.8s), P(0.9s), N(1s)
    final letterDelays = [100, 200, 300, 400, 500, 600, 800, 900, 1000];
    
    for (int i = 0; i < 9; i++) {
      final startMs = letterDelays[i];
      final start = startMs / 1100.0;
      final end = ((startMs + 600) / 1100.0).clamp(0.0, 1.0);
      
      _letterOpacityAnims.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _lettersController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    // Flicker animation (infinite)
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    for (int i = 0; i < 9; i++) {
      _letterFlickerAnims.add(
        Tween<double>(begin: 1.0, end: 0.4).animate(
          CurvedAnimation(
            parent: _flickerController,
            curve: Interval(
              0.41 + (i * 0.005),
              0.43 + (i * 0.005),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );
    }

    // Underline animation
    _underlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Version animation
    _versionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void _startAnimations() {
    // Start letters immediately
    _lettersController.forward();

    // Start flicker after letters appear
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _flickerController.repeat();
    });

    // Start underline at 1s
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _underlineController.forward();
    });

    // Start tagline at 2s
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _taglineController.forward();
    });

    // Start version at 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _versionController.forward();
    });

    // Navigate after 3.5s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) _navigateToNext();
    });
  }

  void _navigateToNext() {
    _flickerController.stop();
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _lettersController.dispose();
    _underlineController.dispose();
    _taglineController.dispose();
    _versionController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a0a),
        body: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text
                  _buildText(),
                  
                  const SizedBox(height: 20),
                  
                  // Underline
                  AnimatedBuilder(
                    animation: _underlineController,
                    builder: (context, _) {
                      return Container(
                        width: 400 * _underlineController.value,
                        height: 4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [green, cyan],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Tagline
                  AnimatedBuilder(
                    animation: _taglineController,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _taglineController.value,
                        child: const Text(
                          'CONNECTING THE WORLD',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0x99FFFFFF),
                            letterSpacing: 4,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Version at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _versionController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _versionController.value,
                    child: const Text(
                      'v1.1.3',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0x40FFFFFF),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText() {
    const letters = ['T', 'I', 'K', 'S', 'A', 'R', ' ', 'V', 'P', 'N'];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(letters.length, (i) {
        if (letters[i] == ' ') {
          return const SizedBox(width: 20);
        }
        
        final isVPN = i >= 7;
        final color = isVPN ? cyan : green;
        
        return AnimatedBuilder(
          animation: Listenable.merge([_lettersController, _flickerController]),
          builder: (context, _) {
            final opacity = _letterOpacityAnims[i >= 7 ? i - 1 : i].value;
            final flickerOpacity = _letterFlickerAnims[i >= 7 ? i - 1 : i].value;
            
            return Opacity(
              opacity: opacity * flickerOpacity,
              child: Text(
                letters[i],
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 4,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
