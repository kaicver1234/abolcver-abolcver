import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/speed_test_provider.dart';
import '../models/speed_test_state.dart';
import '../widgets/vpn_gradient_background.dart';
import '../utils/app_localizations.dart';

class SpeedTestScreen extends StatelessWidget {
  const SpeedTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection: languageProvider.textDirection,
      child: Scaffold(
        body: VPNGradientBackground(
          child: SafeArea(
            child: Consumer<SpeedTestProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    _Header(state: provider.state),
                    Expanded(
                      child: _Content(provider: provider),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Header
// ============================================================================
class _Header extends StatelessWidget {
  final SpeedTestState state;

  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final status = _getStatus(state, tr);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _BackButton(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.translate('speed_test.title_ready'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatus(SpeedTestState state, AppLocalizations tr) {
    if (state.step == SpeedTestStep.loading) return tr.translate('speed_test.measuring_latency');
    if (state.step == SpeedTestStep.download) return tr.translate('speed_test.download_test');
    if (state.step == SpeedTestStep.upload) return tr.translate('speed_test.upload_test');
    if (state.testCompleted) return tr.translate('speed_test.test_completed');
    if (state.hadError) return tr.translate('speed_test.subtitle_error');
    return tr.translate('speed_test.subtitle_ready');
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ============================================================================
// Content
// ============================================================================
class _Content extends StatelessWidget {
  final SpeedTestProvider provider;

  const _Content({required this.provider});

  @override
  Widget build(BuildContext context) {
    final state = provider.state;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _SpeedDisplay(state: state, provider: provider),
          const Spacer(flex: 2),
          if (_shouldShowResults(state)) _ResultsCard(state: state),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool _shouldShowResults(SpeedTestState state) {
    return state.result.ping > 0 || state.testCompleted;
  }
}

// ============================================================================
// Speed Display - Main Circle
// ============================================================================
class _SpeedDisplay extends StatefulWidget {
  final SpeedTestState state;
  final SpeedTestProvider provider;

  const _SpeedDisplay({required this.state, required this.provider});

  @override
  State<_SpeedDisplay> createState() => _SpeedDisplayState();
}

class _SpeedDisplayState extends State<_SpeedDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isIdle = state.step == SpeedTestStep.ready && !state.testCompleted && !state.hadError;
    final isRunning = state.step != SpeedTestStep.ready;
    final isCompleted = state.testCompleted && state.step == SpeedTestStep.ready;
    final hasError = state.hadError && state.errorMessage != null;

    return GestureDetector(
      onTap: () => _handleTap(isRunning),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress Ring
            if (isRunning) _ProgressRing(state: state),
            
            // Main Circle
            _MainCircle(
              isRunning: isRunning,
              isCompleted: isCompleted,
              state: state,
            ),
            
            // Center Content
            _CenterContent(
              state: state,
              isIdle: isIdle,
              isRunning: isRunning,
              isCompleted: isCompleted,
              hasError: hasError,
              pulseController: _pulseController,
              onStart: () => widget.provider.startTest(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(bool isRunning) {
    if (isRunning) {
      widget.provider.stopTest();
    } else {
      widget.provider.startTest();
    }
  }
}

class _ProgressRing extends StatelessWidget {
  final SpeedTestState state;

  const _ProgressRing({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDownload = state.step == SpeedTestStep.download;
    final color = isDownload ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return SizedBox(
      width: 220,
      height: 220,
      child: CircularProgressIndicator(
        value: state.progress,
        strokeWidth: 4,
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _MainCircle extends StatelessWidget {
  final bool isRunning;
  final bool isCompleted;
  final SpeedTestState state;

  const _MainCircle({
    required this.isRunning,
    required this.isCompleted,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (isRunning) {
      bgColor = state.step == SpeedTestStep.download
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : const Color(0xFF3B82F6).withValues(alpha: 0.15);
    } else if (isCompleted) {
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
    } else {
      bgColor = Colors.white.withValues(alpha: 0.05);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    );
  }
}

class _CenterContent extends StatelessWidget {
  final SpeedTestState state;
  final bool isIdle;
  final bool isRunning;
  final bool isCompleted;
  final bool hasError;
  final AnimationController pulseController;
  final VoidCallback onStart;

  const _CenterContent({
    required this.state,
    required this.isIdle,
    required this.isRunning,
    required this.isCompleted,
    required this.hasError,
    required this.pulseController,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    if (hasError) {
      return _ErrorContent(
        message: state.errorMessage ?? tr.translate('speed_test.error_message'),
        onRetry: onStart,
      );
    }

    if (state.step == SpeedTestStep.loading) {
      return _LoadingContent(ping: state.result.ping, tr: tr);
    }

    if (isRunning) {
      return _RunningContent(state: state, tr: tr);
    }

    if (isCompleted) {
      return _CompletedContent(state: state, tr: tr, onRetry: onStart);
    }

    // Idle state
    return _IdleContent(pulseController: pulseController, tr: tr);
  }
}

class _IdleContent extends StatelessWidget {
  final AnimationController pulseController;
  final AppLocalizations tr;

  const _IdleContent({required this.pulseController, required this.tr});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final scale = 1.0 + (pulseController.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 8),
              Text(
                tr.translate('speed_test.go'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingContent extends StatelessWidget {
  final int ping;
  final AppLocalizations tr;

  const _LoadingContent({required this.ping, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${tr.translate('speed_test.ping')}: $ping ${tr.translate('speed_test.ms')}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _RunningContent extends StatelessWidget {
  final SpeedTestState state;
  final AppLocalizations tr;

  const _RunningContent({required this.state, required this.tr});

  @override
  Widget build(BuildContext context) {
    final isDownload = state.step == SpeedTestStep.download;
    final color = isDownload ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final label = isDownload
        ? tr.translate('speed_test.download')
        : tr.translate('speed_test.upload');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.currentSpeed.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr.translate('speed_test.mbps'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedContent extends StatelessWidget {
  final SpeedTestState state;
  final AppLocalizations tr;
  final VoidCallback onRetry;

  const _CompletedContent({
    required this.state,
    required this.tr,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.result.downloadSpeed.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr.translate('speed_test.mbps'),
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorContent({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 36,
          color: Colors.red.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr.translate('speed_test.retry'),
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Results Card
// ============================================================================
class _ResultsCard extends StatelessWidget {
  final SpeedTestState state;

  const _ResultsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _ResultItem(
            icon: Icons.download_rounded,
            label: tr.translate('speed_test.download'),
            value: state.result.downloadSpeed.toStringAsFixed(1),
            unit: tr.translate('speed_test.mbps'),
            color: const Color(0xFF10B981),
          ),
          _Divider(),
          _ResultItem(
            icon: Icons.upload_rounded,
            label: tr.translate('speed_test.upload'),
            value: state.result.uploadSpeed.toStringAsFixed(1),
            unit: tr.translate('speed_test.mbps'),
            color: const Color(0xFF3B82F6),
          ),
          _Divider(),
          _ResultItem(
            icon: Icons.network_ping,
            label: tr.translate('speed_test.ping'),
            value: state.result.ping.toString(),
            unit: tr.translate('speed_test.ms'),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _ResultItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}
