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
    with SingleTickerProviderStateMixin {
  AppLanguage? _selectedLanguage;
  bool _isChangingLanguage = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const Color _cyan = Color(0xFF00D9FF);
  static const Color _green = Color(0xFF00FFA3);
  static const Color _darkBg = Color(0xFF0A0E1A);

  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      language: AppLanguage(name: 'English', code: 'en', flag: '🇺🇸', direction: 'ltr'),
      flag: '🇺🇸',
      displayName: 'English',
      subtitle: 'Continue in English',
      accentColor: Color(0xFF00D9FF),
      bgColor: Color(0xFF0D1E2E),
    ),
    _LanguageOption(
      language: AppLanguage(name: 'فارسی', code: 'fa', flag: '🇮🇷', direction: 'rtl'),
      flag: '🇮🇷',
      displayName: 'فارسی',
      subtitle: 'ادامه به زبان فارسی',
      accentColor: Color(0xFF00FFA3),
      bgColor: Color(0xFF0D1E18),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        setState(() => _selectedLanguage = lang);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _darkBg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _buildHeader(),
                  const Spacer(flex: 2),
                  _buildCards(),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF111827),
            border: Border.all(
              color: _cyan.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_cyan, _green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: const Icon(Icons.language_rounded, size: 32, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_green, _cyan],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Choose Language',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'زبان خود را انتخاب کنید',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.4),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildCards() {
    return Column(
      children: _languages.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final isSelected = _selectedLanguage == opt.language;
        return Padding(
          padding: EdgeInsets.only(bottom: i < _languages.length - 1 ? 14 : 0),
          child: _LanguageCard(
            key: ValueKey(opt.language.code),
            option: opt,
            isSelected: isSelected,
            isLoading: _isChangingLanguage && isSelected,
            onTap: () => _selectLanguage(opt.language),
          ),
        );
      }).toList(),
    );
  }
}

class _LanguageOption {
  final AppLanguage language;
  final String flag;
  final String displayName;
  final String subtitle;
  final Color accentColor;
  final Color bgColor;

  const _LanguageOption({
    required this.language,
    required this.flag,
    required this.displayName,
    required this.subtitle,
    required this.accentColor,
    required this.bgColor,
  });
}

class _LanguageCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? option.bgColor : const Color(0xFF0F1723),
          border: Border.all(
            color: isSelected
                ? option.accentColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Text(option.flag, style: const TextStyle(fontSize: 40, decoration: TextDecoration.none)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? option.accentColor : Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: option.accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? option.accentColor : Colors.transparent,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                        : null,
                  ),
          ],
        ),
      ),
    );
  }
}
