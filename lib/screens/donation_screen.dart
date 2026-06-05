import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../widgets/cyber_glow_background.dart';
import '../widgets/app_background.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> with TickerProviderStateMixin {
  // Unified palette — soft rose/violet tones over the dark background.
  static const Color _accentPrimary = Color(0xFFFF4D8D);   // rose
  static const Color _accentSecondary = Color(0xFFB14BFF); // violet
  static const Color _accentSoft = Color(0xFFFF8FB8);      // light rose

  late AnimationController _controller;
  late AnimationController _heartController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;
  late Animation<double> _heartAnimation;
  late Animation<double> _glowAnimation;

  final Map<String, String> _wallets = {
    'Ethereum (ETH)': '0xae963BF541F90Dd687419C8c442c7d6b85F60d55',
    'Tether (USDT-TRC20)': 'TXd74xCtRAvpZaHsxEYF4WdoHQBLQwo3ob',
    'Tron (TRX)': 'TXd74xCtRAvpZaHsxEYF4WdoHQBLQwo3ob',
    'Toncoin (TON)': 'UQBRCtsfiqEVVdjO9lejWdcq1OumwL2dvht2P0G7aTlXo8mQ',
  };

  int get _animatedItemCount => 3 + _wallets.length + 1;

  List<List<double>> _buildIntervals(int count) {
    final intervals = <List<double>>[];
    const double itemDuration = 0.45;
    final double maxStart = (1.0 - itemDuration).clamp(0.0, 1.0);
    for (int i = 0; i < count; i++) {
      final double start = count <= 1 ? 0.0 : (i / (count - 1)) * maxStart;
      final double end = (start + itemDuration).clamp(0.0, 1.0);
      intervals.add([start, end]);
    }
    return intervals;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final intervals = _buildIntervals(_animatedItemCount);

    _fadeAnims = intervals.map((iv) => CurvedAnimation(
      parent: _controller,
      curve: Interval(iv[0], iv[1], curve: Curves.easeOut),
    )).toList();

    _slideAnims = intervals.map((iv) => Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(iv[0], iv[1], curve: Curves.easeOutCubic),
    ))).toList();

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.96), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.12), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(_heartController);

    _glowAnimation = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  Future<void> _copyToClipboard(String text, String cryptoName) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate('donation.address_copied')
                      .replaceAll('{crypto}', cryptoName),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _accentPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openTrustWallet() async {
    final Uri trustWalletUri = Uri.parse('trust://');
    try {
      final bool launched = await launchUrl(
        trustWalletUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        final Uri storeUri = Uri.parse(
          Theme.of(context).platform == TargetPlatform.iOS
              ? 'https://apps.apple.com/app/trust-crypto-bitcoin-wallet/id1288339409'
              : 'https://play.google.com/store/apps/details?id=com.wallet.crypto.trustapp',
        );
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('donation.wallet_open_error'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: AppBackground(
            useSecondaryBackground: true,
            child: CyberGlowBackground(
              child: SafeArea(
                child: ResponsivePageWrapper(
                  child: Column(
                    children: [
                      _buildHeader(context, responsive, languageProvider),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                          child: Column(
                            children: [
                              SizedBox(height: responsive.scale(28)),
                              _animated(0, _buildDonationIcon(responsive)),
                              SizedBox(height: responsive.scale(26)),
                              _animated(1, _buildTitle(responsive)),
                              SizedBox(height: responsive.scale(12)),
                              _animated(2, Padding(
                                padding: EdgeInsets.symmetric(horizontal: responsive.scale(8)),
                                child: Text(
                                  AppLocalizations.of(context).translate('donation.description'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: responsive.scale(14).clamp(12.0, 16.0),
                                    height: 1.8,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              )),
                              SizedBox(height: responsive.scale(34)),
                              ..._wallets.entries.map((entry) {
                                final index = _wallets.keys.toList().indexOf(entry.key);
                                return _animated(
                                  index + 3,
                                  Padding(
                                    padding: EdgeInsets.only(bottom: responsive.scale(14)),
                                    child: _buildWalletCard(
                                      cryptoName: entry.key,
                                      address: entry.value,
                                      responsive: responsive,
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(height: responsive.scale(20)),
                              _animated(
                                _wallets.length + 3,
                                _buildThankYouCard(responsive),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveHelper responsive, LanguageProvider languageProvider) {
    return Padding(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(responsive.scale(12)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Icon(
                languageProvider.isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                color: Colors.white,
                size: responsive.scale(20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('donation.header'),
              style: GoogleFonts.poppins(
                fontSize: responsive.scale(19).clamp(17.0, 23.0),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(ResponsiveHelper responsive) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, _accentSoft, _accentSecondary],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect),
      child: Text(
        AppLocalizations.of(context).translate('donation.title'),
        style: GoogleFonts.poppins(
          fontSize: responsive.scale(28).clamp(24.0, 34.0),
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDonationIcon(ResponsiveHelper responsive) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return SizedBox(
          width: responsive.scale(150),
          height: responsive.scale(150),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer aurora glow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentPrimary.withValues(alpha: 0.45 * _glowAnimation.value),
                      _accentSecondary.withValues(alpha: 0.25 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              // Inner disc
              Container(
                width: responsive.scale(110),
                height: responsive.scale(110),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A1530), Color(0xFF14091C)],
                  ),
                  border: Border.all(
                    color: _accentPrimary.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentPrimary.withValues(alpha: 0.35 * _glowAnimation.value),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _accentSecondary.withValues(alpha: 0.25 * _glowAnimation.value),
                      blurRadius: 60,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _heartAnimation,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_accentSoft, _accentPrimary, _accentSecondary],
                      ).createShader(rect),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: responsive.scale(58),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletCard({
    required String cryptoName,
    required String address,
    required ResponsiveHelper responsive,
  }) {
    final cryptoColor = _getCryptoColor(cryptoName);

    return Container(
      padding: EdgeInsets.all(responsive.scale(18)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cryptoColor.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.scale(11)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cryptoColor.withValues(alpha: 0.28),
                      cryptoColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cryptoColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cryptoColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  _getCryptoIcon(cryptoName),
                  color: cryptoColor,
                  size: responsive.scale(22),
                ),
              ),
              SizedBox(width: responsive.scale(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cryptoName.split(' ').first,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.scale(16).clamp(14.0, 18.0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      cryptoName.contains('(')
                          ? cryptoName.substring(cryptoName.indexOf('('))
                          : '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: responsive.scale(12).clamp(10.0, 14.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.scale(14)),
          Container(
            padding: EdgeInsets.all(responsive.scale(14)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: responsive.scale(12).clamp(10.0, 14.0),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: responsive.scale(10)),
                GestureDetector(
                  onTap: () => _copyToClipboard(address, cryptoName),
                  child: Container(
                    padding: EdgeInsets.all(responsive.scale(10)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_accentPrimary, _accentSecondary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _accentPrimary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      color: Colors.white,
                      size: responsive.scale(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTrustWalletButton(ResponsiveHelper responsive) {
    return GestureDetector(
      onTap: _openTrustWallet,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: responsive.scale(20),
          horizontal: responsive.scale(24),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accentSecondary, _accentPrimary],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentPrimary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(responsive.scale(8)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: responsive.scale(22),
              ),
            ),
            SizedBox(width: responsive.scale(14)),
            Text(
              AppLocalizations.of(context).translate('donation.open_trust_wallet'),
              style: GoogleFonts.poppins(
                fontSize: responsive.scale(16).clamp(14.0, 18.0),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThankYouCard(ResponsiveHelper responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.scale(22)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentPrimary.withValues(alpha: 0.18),
            _accentSecondary.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _accentPrimary.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentPrimary.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.scale(12)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accentSoft, _accentPrimary],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _accentPrimary.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ScaleTransition(
              scale: _heartAnimation,
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: responsive.scale(26),
              ),
            ),
          ),
          SizedBox(width: responsive.scale(18)),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('donation.thank_you'),
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.scale(14).clamp(12.0, 16.0),
                fontWeight: FontWeight.w600,
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCryptoIcon(String cryptoName) {
    if (cryptoName.contains('Ethereum')) return Icons.diamond_outlined;
    if (cryptoName.contains('Tether')) return Icons.attach_money_rounded;
    if (cryptoName.contains('Tron')) return Icons.flash_on_rounded;
    if (cryptoName.contains('Toncoin')) return Icons.currency_exchange_rounded;
    return Icons.currency_exchange_rounded;
  }

  Color _getCryptoColor(String cryptoName) {
    if (cryptoName.contains('Ethereum')) return const Color(0xFF8B9DFF);
    if (cryptoName.contains('Tether')) return const Color(0xFF4FD1A0);
    if (cryptoName.contains('Tron')) return const Color(0xFFFF5C7A);
    if (cryptoName.contains('Toncoin')) return const Color(0xFF4FB8FF);
    return _accentSecondary;
  }
}
