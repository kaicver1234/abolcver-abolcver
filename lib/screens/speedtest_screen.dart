import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/speed_test_provider.dart';
import '../models/speed_test_state.dart';
import '../widgets/app_background.dart';
import '../widgets/speed_test/modern_speed_gauge.dart';
import '../utils/app_localizations.dart';
import '../services/analytics_service.dart';
import '../utils/responsive_helper.dart';

// ─── Brand palette ─────────────────────────────────────────────────────────
// Mirrors the home screen exactly. We deliberately avoid introducing any new
// hues so the speed test feels like a natural extension of the app shell.
//   • Cyan  → connecting / upload / primary accent
//   • Green → connected / download / success
//   • Red   → destructive (stop, error)
const Color _kCyan = Color(0xFF00D9FF);
const Color _kGreen = Color(0xFF00FFA3);
const Color _kDanger = Color(0xFFFF6B6B);

class SpeedTestScreen extends StatelessWidget {
  const SpeedTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final tr = AppLocalizations.of(context);

    return Directionality(
      textDirection: lp.textDirection,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                lp.isRtl
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              tr.translate('speed_test.title_ready'),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Consumer<SpeedTestProvider>(
            builder: (context, provider, _) {
              final r = ResponsiveHelper(context);
              return ResponsivePageWrapper(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    8,
                    r.horizontalPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: r.responsiveValue(
                              small: 8, medium: 14, large: 18)),

                      // Status pill (mirrors home screen)
                      _StatusPill(state: provider.state),

                      SizedBox(
                          height: r.responsiveValue(
                              small: 22, medium: 28, large: 34)),

                      // Big gauge centerpiece
                      _GaugeStage(state: provider.state),

                      SizedBox(
                          height: r.responsiveValue(
                              small: 24, medium: 30, large: 36)),

                      // Segmented phase progress (replaces dot indicator)
                      _PhaseProgress(state: provider.state),

                      SizedBox(
                          height: r.responsiveValue(
                              small: 26, medium: 32, large: 38)),

                      if (provider.state.hadError) ...[
                        _ErrorMessage(state: provider.state),
                        const SizedBox(height: 18),
                      ],

                      // Result card with all three metrics
                      _ResultCard(state: provider.state),

                      SizedBox(
                          height: r.responsiveValue(
                              small: 26, medium: 32, large: 38)),

                      // Primary action button
                      _PrimaryButton(
                          provider: provider, state: provider.state),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Status pill ───────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final SpeedTestState state;
  const _StatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isRunning = state.step != SpeedTestStep.ready;

    final String text;
    final Color color;

    if (isRunning) {
      if (state.step == SpeedTestStep.loading) {
        text = tr.translate('speed_test.measuring_latency');
        color = _kCyan;
      } else if (state.step == SpeedTestStep.download) {
        text = tr.translate('speed_test.download_test');
        color = _kGreen;
      } else {
        text = tr.translate('speed_test.upload_test');
        color = _kCyan;
      }
    } else if (state.testCompleted) {
      text = tr.translate('speed_test.test_completed');
      color = _kGreen;
    } else if (state.hadError) {
      text = tr.translate('speed_test.title_error');
      color = _kDanger;
    } else {
      text = tr.translate('speed_test.subtitle_ready');
      color = Colors.white.withValues(alpha: 0.5);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey(text),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gauge stage ───────────────────────────────────────────────────────────

class _GaugeStage extends StatelessWidget {
  final SpeedTestState state;
  const _GaugeStage({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final r = ResponsiveHelper(context);
    final isRunning = state.step != SpeedTestStep.ready;
    final color = _phaseColor(state.step);
    final maxScale = _phaseMaxScale(state.step);
    final label = _phaseLabel(state.step, tr, completed: state.testCompleted);
    final value = isRunning ? state.currentSpeed : state.result.downloadSpeed;
    final isIdle = state.step == SpeedTestStep.ready && !state.testCompleted;

    final size = r.scale(270).clamp(220.0, 340.0);

    return SizedBox(
      width: size,
      height: size,
      child: ModernSpeedGauge(
        value: isIdle ? 0 : value,
        maxValue: maxScale,
        color: color,
        label: label,
        size: size,
        isIdle: isIdle,
        centerOverlay: state.step == SpeedTestStep.loading
            ? const _LoadingCenter()
            : null,
      ),
    );
  }
}

class _LoadingCenter extends StatelessWidget {
  const _LoadingCenter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(_kCyan),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'PING',
          style: GoogleFonts.poppins(
            color: _kCyan.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ─── Phase progress (segmented bar) ────────────────────────────────────────

class _PhaseProgress extends StatelessWidget {
  final SpeedTestState state;
  const _PhaseProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final step = state.step;
    final completed = state.testCompleted;

    // Status of each phase: -1 not yet, 0 active, 1 done.
    int pingStatus;
    int downloadStatus;
    int uploadStatus;

    if (completed) {
      pingStatus = 1;
      downloadStatus = 1;
      uploadStatus = 1;
    } else if (step == SpeedTestStep.loading) {
      pingStatus = 0;
      downloadStatus = -1;
      uploadStatus = -1;
    } else if (step == SpeedTestStep.download) {
      pingStatus = 1;
      downloadStatus = 0;
      uploadStatus = -1;
    } else if (step == SpeedTestStep.upload) {
      pingStatus = 1;
      downloadStatus = 1;
      uploadStatus = 0;
    } else {
      pingStatus = -1;
      downloadStatus = -1;
      uploadStatus = -1;
    }

    final segments = <_PhaseSegmentData>[
      _PhaseSegmentData(
        label: tr.translate('speed_test.ping'),
        color: _kCyan,
        status: pingStatus,
      ),
      _PhaseSegmentData(
        label: tr.translate('speed_test.download'),
        color: _kGreen,
        status: downloadStatus,
      ),
      _PhaseSegmentData(
        label: tr.translate('speed_test.upload'),
        color: _kCyan,
        status: uploadStatus,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          Expanded(child: _PhaseSegment(data: segments[i])),
          if (i < segments.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PhaseSegmentData {
  final String label;
  final Color color;
  // -1 pending, 0 active, 1 done
  final int status;
  _PhaseSegmentData({
    required this.label,
    required this.color,
    required this.status,
  });
}

class _PhaseSegment extends StatelessWidget {
  final _PhaseSegmentData data;
  const _PhaseSegment({required this.data});

  @override
  Widget build(BuildContext context) {
    final isActive = data.status == 0;
    final isDone = data.status == 1;
    final highlight = isActive || isDone;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: highlight
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: 3,
          decoration: BoxDecoration(
            color: highlight
                ? data.color
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.55),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

// ─── Result card ───────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final SpeedTestState state;
  const _ResultCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final r = ResponsiveHelper(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.scale(18).clamp(14.0, 24.0),
        vertical: r.scale(18).clamp(14.0, 22.0),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.045),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _ResultStat(
              icon: Icons.network_ping_rounded,
              label: tr.translate('speed_test.ping'),
              value: state.result.ping > 0
                  ? state.result.ping.toString()
                  : '—',
              unit: tr.translate('speed_test.ms'),
              color: _kCyan,
            ),
          ),
          _ResultDivider(),
          Expanded(
            child: _ResultStat(
              icon: Icons.arrow_downward_rounded,
              label: tr.translate('speed_test.download'),
              value: state.result.downloadSpeed > 0
                  ? state.result.downloadSpeed.toStringAsFixed(1)
                  : '—',
              unit: tr.translate('speed_test.mbps'),
              color: _kGreen,
            ),
          ),
          _ResultDivider(),
          Expanded(
            child: _ResultStat(
              icon: Icons.arrow_upward_rounded,
              label: tr.translate('speed_test.upload'),
              value: state.result.uploadSpeed > 0
                  ? state.result.uploadSpeed.toStringAsFixed(1)
                  : '—',
              unit: tr.translate('speed_test.mbps'),
              color: _kCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    final isEmpty = value == '—';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEmpty
                ? Colors.white.withValues(alpha: 0.04)
                : color.withValues(alpha: 0.12),
            border: Border.all(
              color: isEmpty
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isEmpty ? Colors.white.withValues(alpha: 0.25) : color,
            size: r.scale(16).clamp(13.0, 20.0),
          ),
        ),
        SizedBox(height: r.scale(8)),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: r.scale(9.5).clamp(8.5, 11.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: r.scale(6)),
        RichText(
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                  color: isEmpty
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white,
                  fontSize: r.scale(18).clamp(15.0, 22.0),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: r.scale(10).clamp(8.5, 12.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Primary button ────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final SpeedTestProvider provider;
  final SpeedTestState state;
  const _PrimaryButton({required this.provider, required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isRunning = state.step != SpeedTestStep.ready;
    final isStop = isRunning;
    final label = isRunning
        ? tr.translate('speed_test.stop')
        : (state.testCompleted
            ? tr.translate('speed_test.test_again')
            : tr.translate('speed_test.start_test'));

    // Brand-aligned gradients only.
    //   • Idle / again: cyan→green sweep, matches the home connect button vibe.
    //   • Running:      red, signals destructive stop.
    final List<Color> gradientColors;
    final Color borderColor;
    final List<BoxShadow>? shadow;
    if (isStop) {
      gradientColors = [
        _kDanger.withValues(alpha: 0.95),
        _kDanger.withValues(alpha: 0.7),
      ];
      borderColor = _kDanger.withValues(alpha: 0.5);
      shadow = [
        BoxShadow(
          color: _kDanger.withValues(alpha: 0.30),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
    } else {
      gradientColors = [
        _kCyan.withValues(alpha: 0.95),
        _kGreen.withValues(alpha: 0.85),
      ];
      borderColor = Colors.white.withValues(alpha: 0.20);
      shadow = [
        BoxShadow(
          color: _kCyan.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: GestureDetector(
        onTap: () {
          if (isRunning) {
            provider.stopTest();
          } else {
            AnalyticsService().logSpeedTestStart();
            provider.startTest();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: shadow,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isStop
                    ? Icons.stop_rounded
                    : (state.testCompleted
                        ? Icons.refresh_rounded
                        : Icons.play_arrow_rounded),
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final SpeedTestState state;
  const _ErrorMessage({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final errorKey = state.errorMessage ?? 'test_failed';
    final msg = tr.translate('speed_test.$errorKey');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kDanger.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              color: _kDanger.withValues(alpha: 0.85), size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _kDanger.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

Color _phaseColor(SpeedTestStep s) {
  switch (s) {
    case SpeedTestStep.download:
      return _kGreen;
    case SpeedTestStep.upload:
      return _kCyan;
    case SpeedTestStep.loading:
      return _kCyan;
    case SpeedTestStep.ready:
      return _kGreen;
  }
}

double _phaseMaxScale(SpeedTestStep s) {
  switch (s) {
    case SpeedTestStep.download:
      return 100;
    case SpeedTestStep.upload:
      return 50;
    default:
      return 100;
  }
}

String? _phaseLabel(SpeedTestStep s, AppLocalizations tr,
    {bool completed = false}) {
  switch (s) {
    case SpeedTestStep.download:
      return tr.translate('speed_test.download').toUpperCase();
    case SpeedTestStep.upload:
      return tr.translate('speed_test.upload').toUpperCase();
    case SpeedTestStep.loading:
      return null;
    case SpeedTestStep.ready:
      return completed
          ? tr.translate('speed_test.download').toUpperCase()
          : null;
  }
}
