import 'package:flutter/material.dart';

class SplashLoadingScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashLoadingScreen({super.key, required this.nextScreen});

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _dotsCtrl;

  late List<Animation<double>> _letterSlide;
  late List<Animation<double>> _letterFade;

  late Animation<double> _vpnSlide;
  late Animation<double> _vpnFade;
  late Animation<double> _tagSlide;
  late Animation<double> _tagFade;
  late Animation<double> _bottomFade;

  late List<Animation<double>> _dotOpacity;

  static const _bg = Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotOpacity = List.generate(3, (i) {
      final start = i * 0.22;
      return Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotsCtrl,
          curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeInOut),
        ),
      );
    });

    final starts = [0.03, 0.06, 0.09, 0.12, 0.15, 0.18];
    _letterSlide = starts.map((s) => Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(s, s + 0.17, curve: Curves.easeOutCubic)),
    )).toList();
    _letterFade = starts.map((s) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(s, s + 0.17, curve: Curves.easeOut)),
    )).toList();

    _vpnSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.22, 0.36, curve: Curves.easeOut)),
    );
    _vpnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.22, 0.36, curve: Curves.easeOut)),
    );

    _tagSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.28, 0.42, curve: Curves.easeOut)),
    );
    _tagFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.28, 0.42, curve: Curves.easeOut)),
    );

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.30, 0.42, curve: Curves.easeOut)),
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3400), () {
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
    _ctrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  double _sw(double base, double w) => (base * w / 375).clamp(base * 0.72, base * 1.35);
  double _sh(double base, double h) => (base * h / 812).clamp(base * 0.72, base * 1.35);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTiksarRow(w),
                      SizedBox(height: _sh(4, h)),
                      Transform.translate(
                        offset: Offset(0, _vpnSlide.value),
                        child: Opacity(
                          opacity: _vpnFade.value,
                          child: _buildVpnRow(w),
                        ),
                      ),
                      SizedBox(height: _sh(24, h)),
                      Transform.translate(
                        offset: Offset(0, _tagSlide.value),
                        child: Opacity(
                          opacity: _tagFade.value,
                          child: _buildTagline(w),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _bottomFade.value,
                    child: _buildBottom(h),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTiksarRow(double w) {
    const letters = ['T', 'I', 'K', 'S', 'A', 'R'];
    final fontSize = _sw(58, w);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(letters.length, (i) {
        return Transform.translate(
          offset: Offset(0, _letterSlide[i].value),
          child: Opacity(
            opacity: _letterFade[i].value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _sw(1.5, w)),
              child: Text(
                letters[i],
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVpnRow(double w) {
    final lineW = _sw(36, w);
    final fontSize = _sw(16, w);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: lineW, height: 1.0, color: Colors.white.withValues(alpha: 0.18)),
        SizedBox(width: _sw(10, w)),
        Text(
          'VPN',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 5,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(width: _sw(10, w)),
        Container(width: lineW, height: 1.0, color: Colors.white.withValues(alpha: 0.18)),
      ],
    );
  }

  Widget _buildTagline(double w) {
    return Text(
      'FAST  ·  SECURE  ·  FREE',
      style: TextStyle(
        fontSize: _sw(11, w),
        color: Colors.white.withValues(alpha: 0.2),
        letterSpacing: 3,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildBottom(double h) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: _sh(48, h)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _dotsCtrl,
              builder: (_, __) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: _sw(4, h)),
                      width: _sw(4.5, h),
                      height: _sw(4.5, h),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: _dotOpacity[i].value),
                      ),
                    );
                  }),
                );
              },
            ),
            SizedBox(height: _sh(16, h)),
            Text(
              'v1.1.5',
              style: TextStyle(
                fontSize: _sh(10, h),
                color: Colors.white.withValues(alpha: 0.1),
                letterSpacing: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
