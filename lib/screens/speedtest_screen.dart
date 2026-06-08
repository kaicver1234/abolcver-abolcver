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

const Color _kPing = Color(0xFFA78BFA);
const Color _kDownload = Color(0xFF00FFA3);
const Color _kUpload = Color(0xFF00D9FF);
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
                      SizedBox(height: r.responsiveValue(small: 8, medium: 14, large: 18)),

                      // Status pill (mirrors home screen)
                      _StatusPill(state: provider.state),

                      SizedBox(height: r.responsiveValue(small: 22, medium: 28, large: 34)),

                      // Big gauge centerpiece (no card wrapper, like home button)
                      _GaugeStage(state: provider.state),

                      SizedBox(height: r.responsiveValue(small: 22, medium: 28, large: 34)),

                      // Phase indicator dots
                      _PhaseDots(state: provider.state),

                      SizedBox(height: r.responsiveValue(small: 26, medium: 32, large: 38)),

                      if (provider.state.hadError) ...[
                        _ErrorMessage(state: provider.state),
                        const SizedBox(height: 18),
                      ],

                      // Simple stats row (no card)
                      _SimpleStatsRow(state: provider.state),

                      SizedBox(height: r.responsiveValue(small: 30, medium: 36, large: 42)),

                      // Primary action button
                      _PrimaryButton(provider: provider, state: provider.state),

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
        color = _kPing;
      } else if (state.step == SpeedTestStep.download) {
        text = tr.translate('speed_test.download_test');
        color = _kDownload;
      } else {
        text = tr.translate('speed_test.upload_test');
        color = _kUpload;
      }
    } else if (state.testCompleted) {
      text = tr.translate('speed_test.test_completed');
      color = _kDownload;
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
    return const SizedBox(
      width: 36,
      height: 36,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation(_kPing),
      ),
    );
  }
}

// ─── Phase dots (minimal indicator) ────────────────────────────────────────

class _PhaseDots extends StatelessWidget {
  final SpeedTestState state;
  const _PhaseDots({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final step = state.step;
    final completed = state.testCompleted;

    final phases = <_PhaseDotData>[
      _PhaseDotData(
        tr.translate('speed_test.ping'),
        _kPing,
        active: step == SpeedTestStep.loading,
        done: completed ||
            step == SpeedTestStep.download ||
            step == SpeedTestStep.upload,
      ),
      _PhaseDotData(
        tr.translate('speed_test.download'),
        _kDownload,
        active: step == SpeedTestStep.download,
        done: completed || step == SpeedTestStep.upload,
      ),
      _PhaseDotData(
        tr.translate('speed_test.upload'),
        _kUpload,
        active: step == SpeedTestStep.upload,
        done: completed,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < phases.length; i++) ...[
          _PhaseDot(data: phases[i]),
          if (i < phases.length - 1)
            Container(
              width: 22,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.white.withValues(alpha: 0.08),
            ),
        ],
      ],
    );
  }
}

class _PhaseDotData {
  final String label;
  final Color color;
  final bool active;
  final bool done;
  _PhaseDotData(this.label, this.color, {required this.active, required this.done});
}

class _PhaseDot extends StatelessWidget {
  final _PhaseDotData data;
  const _PhaseDot({required this.data});

  @override
  Widget build(BuildContext context) {
    final highlight = data.active || data.done;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlight ? data.color : Colors.white.withValues(alpha: 0.18),
              boxShadow: data.active
                  ? [
                      BoxShadow(
                        color: data.color.withValues(alpha: 0.65),
                        blurRadius: 9,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 7),
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
        ],
      ),
    );
  }
}

// ─── Simple stats row (mirrors home screen _buildSimpleStats) ──────────────

class _SimpleStatsRow extends StatelessWidget {
  final SpeedTestState state;
  const _SimpleStatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SimpleStatItem(
            icon: Icons.network_ping_rounded,
            label: tr.translate('speed_test.ping'),
            value: state.result.ping > 0 ? state.result.ping.toString() : '—',
            unit: tr.translate('speed_test.ms'),
            color: _kPing,
          ),
        ),
        Expanded(
          child: _SimpleStatItem(
            icon: Icons.arrow_downward_rounded,
            label: tr.translate('speed_test.download'),
            value: state.result.downloadSpeed > 0
                ? state.result.downloadSpeed.toStringAsFixed(1)
                : '—',
            unit: tr.translate('speed_test.mbps'),
            color: _kDownload,
          ),
        ),
        Expanded(
          child: _SimpleStatItem(
            icon: Icons.arrow_upward_rounded,
            label: tr.translate('speed_test.upload'),
            value: state.result.uploadSpeed > 0
                ? state.result.uploadSpeed.toStringAsFixed(1)
                : '—',
            unit: tr.translate('speed_test.mbps'),
            color: _kUpload,
          ),
        ),
      ],
    );
  }
}

class _SimpleStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SimpleStatItem({
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
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: r.scale(10.5).clamp(9.0, 12.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: r.scale(8)),
        Icon(
          icon,
          color: isEmpty ? Colors.white.withValues(alpha: 0.25) : color,
          size: r.scale(18).clamp(14.0, 22.0),
        ),
        SizedBox(height: r.scale(8)),
        RichText(
          textAlign: TextAlign.center,
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
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: r.scale(10.5).clamp(9.0, 13.0),
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

    final gradientColors = isStop
        ? [_kDanger.withValues(alpha: 0.95), _kDanger.withValues(alpha: 0.7)]
        : [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.07),
          ];
    final borderColor = isStop
        ? _kDanger.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.18);

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
            boxShadow: isStop
                ? [
                    BoxShadow(
                      color: _kDanger.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isStop ? Icons.stop_rounded : Icons.play_arrow_rounded,
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
    return Row(
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
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

Color _phaseColor(SpeedTestStep s) {
  switch (s) {
    case SpeedTestStep.download:
      return _kDownload;
    case SpeedTestStep.upload:
      return _kUpload;
    case SpeedTestStep.loading:
      return _kPing;
    case SpeedTestStep.ready:
      return _kDownload;
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
      return completed ? tr.translate('speed_test.download').toUpperCase() : null;
  }
}
