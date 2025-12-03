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
  
  // Animation controllers
  late AnimationController _tLogoController;
  late AnimationController _lettersController;
  late AnimationController _zoomController;

  // T Logo animations
  late Animation<double> _barTopAnimation;
  late Animation<double> _barVerticalAnimation;
  late Animation<double> _tLogoMoveAnimation;

  // Letter animations
  final List<Animation<double>> _letterAnimations = [];

  // Zoom animation
  late Animation<double> _zoomAnimation;
  late Animation<double> _opacityAnimation;

  // Letters for animation
  final List<String> _tiksarLetters = ['I', 'K', 'S', 'A', 'R'];
  final List<String> _vpnLetters = ['V', 'P', 'N'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // T Logo controller (0-1s)
    _tLogoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _barTopAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _tLogoController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _barVerticalAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _tLogoController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _tLogoMoveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _tLogoController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Letters controller
    _lettersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create animations for each letter (IKSAR + space + VPN = 9 items)
    for (int i = 0; i < 9; i++) {
      final start = i * 0.08;
      final end = start + 0.25;
      _letterAnimations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _lettersController,
            curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOut),
          ),
        ),
      );
    }

    // Zoom controller
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _zoomAnimation = Tween<double>(begin: 1, end: 30).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _startAnimationSequence() async {
    // Start T logo animation
    _tLogoController.forward();

    // Wait then start letters
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _lettersController.forward();

    // Wait then start zoom
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _zoomController.forward();

    // Navigate after zoom
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _navigateToNext();
  }

  void _navigateToNext() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _tLogoController.dispose();
    _lettersController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final fontSize = isSmallScreen ? 32.0 : (screenWidth < 600 ? 40.0 : 50.0);
    final logoSize = isSmallScreen ? 35.0 : (screenWidth < 600 ? 45.0 : 55.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1629),
              Color(0xFF0A0E1A),
              Color(0xFF050709),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_tLogoController, _lettersController, _zoomController]),
          builder: (context, child) {
            return Center(
              child: Transform.scale(
                scale: _zoomAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // T Logo
                      _buildTLogo(logoSize),
                      
                      // Letters
                      ..._buildLetters(fontSize),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTLogo(double size) {
    final barThickness = size * 0.26;
    final logoHeight = size * 2;
    final moveOffset = 8.0 * _tLogoMoveAnimation.value;

    return Padding(
      padding: EdgeInsets.only(right: moveOffset),
      child: SizedBox(
        width: size,
        height: logoHeight,
        child: Stack(
          children: [
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Transform.scale(
                scaleX: _barTopAnimation.value,
                child: Container(
                  height: barThickness,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Vertical bar
            Positioned(
              top: barThickness,
              left: (size - barThickness) / 2,
              child: Transform.scale(
                scaleY: _barVerticalAnimation.value,
                alignment: Alignment.topCenter,
                child: Container(
                  width: barThickness,
                  height: logoHeight - barThickness,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLetters(double fontSize) {
    final List<Widget> widgets = [];

    // IKSAR letters (indices 0-4)
    for (int i = 0; i < _tiksarLetters.length; i++) {
      widgets.add(_buildLetter(_tiksarLetters[i], fontSize, i, true));
    }

    // Space (index 5)
    widgets.add(
      AnimatedBuilder(
        animation: _letterAnimations[5],
        builder: (context, child) {
          return SizedBox(width: fontSize * 0.3 * _letterAnimations[5].value);
        },
      ),
    );

    // VPN letters (indices 6-8)
    for (int i = 0; i < _vpnLetters.length; i++) {
      widgets.add(_buildLetter(_vpnLetters[i], fontSize, i + 6, false));
    }

    return widgets;
  }

  Widget _buildLetter(String letter, double fontSize, int index, bool isGreen) {
    return AnimatedBuilder(
      animation: _letterAnimations[index],
      builder: (context, child) {
        final progress = _letterAnimations[index].value;
        return Transform.translate(
          offset: Offset(0, 50 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Text(
              letter,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isGreen ? FontWeight.w700 : FontWeight.w600,
                color: isGreen ? const Color(0xFF10B981) : Colors.white,
                letterSpacing: 2,
                shadows: isGreen
                    ? [
                        Shadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 30,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
