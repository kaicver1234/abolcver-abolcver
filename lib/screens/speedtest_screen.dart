import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/speed_test_provider.dart';
import '../models/speed_test_state.dart';
import '../widgets/app_background.dart';
import '../widgets/speed_test/modern_speed_gauge.dart';
import '../utils/app_localizations.dart';
import '../services/analytics_service.dart';
import '../utils/responsive_helper.dart';

// Shared palette with the routing/per-app screens so the app feels consistent.
const Color _kBg = Color(0xFF0A0A0A);
const Color _kCard = Color(0xFF111111);
const Color _kBorder = Color(0xFF222222);
const Color _kAccent = Color(0xFF00D9FF);
const Color _kDownload = Color(0xFF00FFA3);
const Color _kUpload = Color(0xFF00D9FF);
const Color _kPing = Color(0xFFB388FF);
const Color _kDanger = Color(0xFFEF4444);

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
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: _kBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                lp.isRtl
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              tr.translate('speed_test.title_ready'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Consumer<SpeedTestProvider>(
            builder: (context, provider, _) {
              final r = ResponsiveHelper(context);
              return ResponsivePageWrapper(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    8,
                    r.horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(state: provider.state),
                      const SizedBox(height: 20),
                      _PhaseStepper(state: provider.state),
                      const SizedBox(height: 20),
                      _GaugeCard(state: provider.state),
                      const SizedBox(height: 16),
                      if (provider.state.hadError) ...[
                        _ErrorMessage(state: provider.state),
                        const SizedBox(height: 16),
                      ],
                      _SectionLabel(
                        text: tr.translate('speed_test.test_completed'),
                      ),
                      const SizedBox(height: 10),
                      _ResultsCard(state: provider.state),
                      const SizedBox(height: 24),
                      _PrimaryButton(provider: provider, state: provider.state),
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

// ─── Hero card (matches routing screen hero) ────────────────────────────────

class _HeroCard extends StatelessWidget {
  final SpeedTestState state;
  const _HeroCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isRunning = state.step != SpeedTestStep.ready;
    final accent = _phaseColor(state.step);

    final String title;
    final String subtitle;
    if (isRunning) {
      title = tr.translate('speed_test.title_testing');
      subtitle = _subtitle(state, tr);
    } else if (state.testCompleted) {
      title = tr.translate('speed_test.title_completed');
      subtitle = tr.translate('speed_test.subtitle_completed');
    } else if (state.hadError) {
      title = tr.translate('speed_test.title_error');
      subtitle = tr.translate('speed_test.subtitle_error');
    } else {
      title = tr.translate('speed_test.title_ready');
      subtitle = tr.translate('speed_test.subtitle_ready');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isRunning
                  ? accent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isRunning ? accent.withValues(alpha: 0.3) : _kBorder,
              ),
            ),
            child: Icon(
              Icons.speed_rounded,
              color: isRunning ? accent : Colors.white70,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(SpeedTestState s, AppLocalizations tr) {
    if (s.step == SpeedTestStep.loading) {
      return tr.translate('speed_test.measuring_latency');
    }
    if (s.step == SpeedTestStep.download) {
      return tr.translate('speed_test.download_test');
    }
    if (s.step == SpeedTestStep.upload) {
      return tr.translate('speed_test.upload_test');
    }
    return tr.translate('speed_test.subtitle_testing');
  }
}

// ─── Phase stepper ──────────────────────────────────────────────────────────

class _PhaseStepper extends StatelessWidget {
  final SpeedTestState state;
  const _PhaseStepper({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final step = state.step;
    final completed = state.testCompleted;

    final phases = <_PhaseChipData>[
      _PhaseChipData(
        tr.translate('speed_test.ping'),
        _kPing,
        step == SpeedTestStep.loading,
        completed ||
            step == SpeedTestStep.download ||
            step == SpeedTestStep.upload,
      ),
      _PhaseChipData(
        tr.translate('speed_test.download'),
        _kDownload,
        step == SpeedTestStep.download,
        completed || step == SpeedTestStep.upload,
      ),
      _PhaseChipData(
        tr.translate('speed_test.upload'),
        _kUpload,
        step == SpeedTestStep.upload,
        completed,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < phases.length; i++) ...[
          _PhaseChip(data: phases[i]),
          if (i < phases.length - 1)
            Container(
              width: 18,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: Colors.white.withValues(alpha: 0.15),
            ),
        ],
      ],
    );
  }
}

class _PhaseChipData {
  final String label;
  final Color color;
  final bool active;
  final bool done;
  _PhaseChipData(this.label, this.color, this.active, this.done);
}

class _PhaseChip extends StatelessWidget {
  final _PhaseChipData data;
  const _PhaseChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final highlight = data.active || data.done;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? data.color.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? data.color.withValues(alpha: data.active ? 0.6 : 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  highlight ? data.color : Colors.white.withValues(alpha: 0.3),
              boxShadow: data.active
                  ? [BoxShadow(color: data.color, blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color:
                  highlight ? data.color : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gauge card ─────────────────────────────────────────────────────────────

class _GaugeCard extends StatelessWidget {
  final SpeedTestState state;
  const _GaugeCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isRunning = state.step != SpeedTestStep.ready;
    final color = _phaseColor(state.step);
    final maxScale = _phaseMaxScale(state.step);
    final label = _phaseLabel(state.step, tr);
    final value = isRunning ? state.currentSpeed : state.result.downloadSpeed;
    final isIdle = state.step == SpeedTestStep.ready && !state.testCompleted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: ModernSpeedGauge(
          value: isIdle ? 0 : value,
          maxValue: maxScale,
          color: color,
          label: label,
          size: 260,
          isIdle: isIdle,
          centerOverlay: state.step == SpeedTestStep.loading
              ? const _LoadingCenter()
              : null,
        ),
      ),
    );
  }
}

class _LoadingCenter extends StatelessWidget {
  const _LoadingCenter();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(_kPing),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr.translate('speed_test.measuring_latency'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Results card ───────────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final SpeedTestState state;
  const _ResultsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _ResultCell(
            icon: Icons.network_ping,
            color: _kPing,
            label: tr.translate('speed_test.ping'),
            value: state.result.ping > 0 ? state.result.ping.toString() : '—',
            unit: tr.translate('speed_test.ms'),
          ),
          _divider(),
          _ResultCell(
            icon: Icons.arrow_downward_rounded,
            color: _kDownload,
            label: tr.translate('speed_test.download'),
            value: state.result.downloadSpeed > 0
                ? state.result.downloadSpeed.toStringAsFixed(1)
                : '—',
            unit: tr.translate('speed_test.mbps'),
          ),
          _divider(),
          _ResultCell(
            icon: Icons.arrow_upward_rounded,
            color: _kUpload,
            label: tr.translate('speed_test.upload'),
            value: state.result.uploadSpeed > 0
                ? state.result.uploadSpeed.toStringAsFixed(1)
                : '—',
            unit: tr.translate('speed_test.mbps'),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 38,
        color: Colors.white.withValues(alpha: 0.06),
      );
}

class _ResultCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;

  const _ResultCell({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: value == '—'
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Misc ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final SpeedTestProvider provider;
  final SpeedTestState state;
  const _PrimaryButton({required this.provider, required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isRunning = state.step != SpeedTestStep.ready;
    final color = isRunning ? _kDanger : _kAccent;
    final label = isRunning
        ? tr.translate('speed_test.stop')
        : (state.testCompleted
            ? tr.translate('speed_test.test_again')
            : tr.translate('speed_test.start_test'));

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          if (isRunning) {
            provider.stopTest();
          } else {
            AnalyticsService().logSpeedTestStart();
            provider.startTest();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kDanger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDanger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: _kDanger.withValues(alpha: 0.85), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: _kDanger.withValues(alpha: 0.95),
                fontSize: 12,
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
      return _kDownload;
    case SpeedTestStep.upload:
      return _kUpload;
    case SpeedTestStep.loading:
      return _kPing;
    case SpeedTestStep.ready:
      return _kAccent;
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

String? _phaseLabel(SpeedTestStep s, AppLocalizations tr) {
  switch (s) {
    case SpeedTestStep.download:
      return tr.translate('speed_test.download').toUpperCase();
    case SpeedTestStep.upload:
      return tr.translate('speed_test.upload').toUpperCase();
    case SpeedTestStep.loading:
      return null;
    case SpeedTestStep.ready:
      return null;
  }
}
