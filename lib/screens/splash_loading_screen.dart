import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashLoadingScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashLoadingScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen> {
  bool _isFarsi = false;

  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  String _t(String en, String fa) => _isFarsi ? fa : en;

  Future<void> _loadAndNavigate() async {
    // Load language preference
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      if (mounted) {
        setState(() => _isFarsi = languageCode == 'fa');
      }
    } catch (e) {
      debugPrint('Language load error: $e');
    }

    // Wait 2 seconds for splash display
    await Future.delayed(const Duration(seconds: 2));

    // Navigate to next screen
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A5F),
              Color(0xFF0D9488),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // App Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'T',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'iksar ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    'VPN',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
              
              // Subtitle
              Text(
                _t(
                  'Secure & Fast Internet Access',
                  'دسترسی امن و سریع به اینترنت',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Loading indicator
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
