import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/responsive_helper.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  // ── Brand palette — mirrors the home screen exactly ──────────────────────
  //   • Pure black background (AppBackground uses 0xFF000000)
  //   • Cards: white @ 0.035 fill, white @ 0.07 border, radius 20
  //   • Accents: cyan (primary) and green (success) — NO other hues
  static const _cyan = Color(0xFF00D9FF);
  static const _bg = Color(0xFF000000);

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _scaleAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutBack,
    ).drive(Tween(begin: 0.85, end: 1.0));

    _fadeAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));

    _slideAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: 24.0, end: 0.0));

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
        return Directionality(
          textDirection: langProvider.textDirection,
          child: PopScope(
            canPop: !widget.updateInfo.isForced,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper(context).scale(20).clamp(16.0, 48.0),
                vertical: ResponsiveHelper(context).scale(40).clamp(24.0, 72.0),
              ),
              child: AnimatedBuilder(
                animation: _enterController,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: _buildCard(context, langProvider),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, LanguageProvider langProvider) {
    final r = ResponsiveHelper(context);
    return Container(
      constraints: BoxConstraints(maxWidth: r.isTablet ? 460 : 360),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.07),
            blurRadius: 40,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopBanner(),
            _buildBody(context, langProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    final r = ResponsiveHelper(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        r.scale(24).clamp(18.0, 32.0),
        r.scale(32).clamp(22.0, 42.0),
        r.scale(24).clamp(18.0, 32.0),
        r.scale(28).clamp(20.0, 38.0),
      ),
      decoration: BoxDecoration(
        // Deep, muted wash on black — barely-there tint instead of a bright
        // gradient, keeping the dialog dark like the rest of the app.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cyan.withValues(alpha: 0.035),
            Colors.white.withValues(alpha: 0.012),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            widget.updateInfo.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: r.scale(20).clamp(16.0, 26.0),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: r.scale(10).clamp(6.0, 16.0)),
          // Version pill
          _buildVersionBadge(),
        ],
      ),
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: _cyan.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _cyan.withValues(alpha: 0.4), blurRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'v${widget.updateInfo.version}  •  New Update',
            style: GoogleFonts.poppins(
              color: _cyan.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LanguageProvider langProvider) {
    final r = ResponsiveHelper(context);
    final pad = r.scale(20).clamp(14.0, 28.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Changelog section
          _buildChangelog(context, langProvider),
          const SizedBox(height: 16),
          // Buttons
          _buildUpdateButton(context),
          if (!widget.updateInfo.isForced) ...[
            const SizedBox(height: 10),
            _buildLaterButton(context),
          ],
          if (widget.updateInfo.isForced) ...[
            const SizedBox(height: 14),
            _buildForcedWarning(context),
          ],
        ],
      ),
    );
  }

  Widget _buildChangelog(BuildContext context, LanguageProvider langProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Same card treatment as the home screen cards.
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _cyan, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('update.new_changes'),
                style: GoogleFonts.poppins(
                  color: _cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.updateInfo.message,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.65,
              decoration: TextDecoration.none,
            ),
            textAlign: langProvider.isRtl ? TextAlign.right : TextAlign.left,
            textDirection: langProvider.textDirection,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(BuildContext context) {
    final r = ResponsiveHelper(context);
    return GestureDetector(
      onTap: _handleUpdate,
      child: Container(
        width: double.infinity,
        height: r.scale(52).clamp(44.0, 64.0),
        decoration: BoxDecoration(
          // Dark cyan-tinted surface with a defined edge — reads as the
          // primary action without the loud bright gradient.
          color: _cyan.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _cyan.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded,
                color: _cyan.withValues(alpha: 0.95), size: 20),
            const SizedBox(width: 8),
            Text(
              widget.updateInfo.isForced
                  ? AppLocalizations.of(context).translate('update.forced_update')
                  : AppLocalizations.of(context).translate('update.download_update'),
              style: GoogleFonts.poppins(
                color: _cyan.withValues(alpha: 0.95),
                fontSize: r.scale(15).clamp(13.0, 18.0),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaterButton(BuildContext context) {
    final r = ResponsiveHelper(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        height: r.scale(46).clamp(40.0, 58.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate('update.remind_later'),
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForcedWarning(BuildContext context) {
    // Forced updates use the brand cyan accent rather than an off-palette
    // orange, so the dialog never breaks the two-hue home language.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _cyan.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded,
              color: _cyan.withValues(alpha: 0.9), size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              AppLocalizations.of(context).translate('update.must_update'),
              style: GoogleFonts.poppins(
                color: _cyan.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    final url = Uri.tryParse(widget.updateInfo.downloadUrl);
    if (url == null) return;

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!widget.updateInfo.isForced && mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {}
  }
}
