import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';
import '../utils/app_localizations.dart';
import '../utils/responsive_helper.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // ── Brand palette — mirrors the home screen exactly ──────────────────────
  //   • Pure black background (AppBackground uses 0xFF000000)
  //   • Cards: white @ 0.035 fill, white @ 0.07 border
  //   • Accent: cyan only — keeps the dialog in the home's two-hue language
  static const _cyan = Color(0xFF00D9FF);
  static const _bg = Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      duration: const Duration(milliseconds: 360),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: 0.92, end: 1.0));
    _fadeAnim = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  /// Split the changelog message into trimmed, non-empty lines so it can be
  /// rendered as a clean bullet list. Falls back to a single paragraph.
  List<String> get _changelogLines => widget.updateInfo.message
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'^\s*[-•*]\s*'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    // Fixed layout direction — the update dialog stays the same regardless of
    // the app language, so it never flips to RTL.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PopScope(
        canPop: !widget.updateInfo.isForced,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper(context).scale(24).clamp(20.0, 48.0),
            vertical: ResponsiveHelper(context).scale(40).clamp(24.0, 72.0),
          ),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: _buildCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final r = ResponsiveHelper(context);
    final pad = r.scale(24).clamp(20.0, 30.0);

    return Container(
      constraints: BoxConstraints(maxWidth: r.isTablet ? 440 : 350),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.06),
            blurRadius: 48,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(r),
            SizedBox(height: r.scale(18).clamp(14.0, 24.0)),
            _buildTitle(r),
            SizedBox(height: r.scale(8).clamp(6.0, 12.0)),
            _buildVersionBadge(),
            SizedBox(height: r.scale(20).clamp(16.0, 26.0)),
            _buildChangelog(context, r),
            if (widget.updateInfo.isForced) ...[
              SizedBox(height: r.scale(14).clamp(10.0, 18.0)),
              _buildForcedWarning(context),
            ],
            SizedBox(height: r.scale(22).clamp(18.0, 28.0)),
            _buildUpdateButton(context, r),
            if (!widget.updateInfo.isForced) ...[
              SizedBox(height: r.scale(8).clamp(6.0, 12.0)),
              _buildLaterButton(context, r),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ResponsiveHelper r) {
    final size = r.scale(64).clamp(54.0, 80.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _cyan.withValues(alpha: 0.16),
            _cyan.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: _cyan.withValues(alpha: 0.28), width: 1),
      ),
      child: Icon(
        Icons.rocket_launch_rounded,
        color: _cyan,
        size: size * 0.46,
      ),
    );
  }

  Widget _buildTitle(ResponsiveHelper r) {
    return Text(
      widget.updateInfo.title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: r.scale(19).clamp(16.0, 24.0),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        decoration: TextDecoration.none,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _cyan.withValues(alpha: 0.06),
        border: Border.all(color: _cyan.withValues(alpha: 0.22), width: 1),
      ),
      child: Text(
        'v${widget.updateInfo.version}',
        style: GoogleFonts.poppins(
          color: _cyan.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildChangelog(BuildContext context, ResponsiveHelper r) {
    final lines = _changelogLines;
    final isList = lines.length > 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: _cyan.withValues(alpha: 0.9), size: 14),
              const SizedBox(width: 7),
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
          if (isList)
            ...lines.map(_buildChangelogItem)
          else
            Text(
              widget.updateInfo.message,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.65,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.left,
            ),
        ],
      ),
    );
  }

  Widget _buildChangelogItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_rounded,
                color: _cyan.withValues(alpha: 0.7), size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(BuildContext context, ResponsiveHelper r) {
    return _PressableButton(
      onTap: _handleUpdate,
      child: Container(
        width: double.infinity,
        height: r.scale(52).clamp(46.0, 60.0),
        decoration: BoxDecoration(
          color: _cyan.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cyan.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: 0.14),
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
                  ? AppLocalizations.of(context)
                      .translate('update.forced_update')
                  : AppLocalizations.of(context)
                      .translate('update.download_update'),
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

  Widget _buildLaterButton(BuildContext context, ResponsiveHelper r) {
    return _PressableButton(
      onTap: () => Navigator.of(context).pop(),
      child: SizedBox(
        width: double.infinity,
        height: r.scale(44).clamp(40.0, 54.0),
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate('update.remind_later'),
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.20), width: 1),
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

/// Lightweight tap-scale feedback — no Material ink, no blur, so it stays
/// smooth on low-end devices.
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableButton({required this.child, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
