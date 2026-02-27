import 'package:flutter/material.dart';
import '../../models/speed_test_state.dart';
import '../../utils/app_colors.dart';
import 'semicircular_progress_painter.dart';
import 'animated_grid_painter.dart';

class SpeedTestProgressIndicator extends StatefulWidget {
  final double progress;
  final Color? color;
  final bool showButton;
  final bool showLoadingIndicator;
  final double? centerValue;
  final String? centerUnit;
  final String? subtitle;
  final SpeedTestResult? result;
  final Widget? button;
  final SpeedTestStep? currentStep;

  const SpeedTestProgressIndicator({
    super.key,
    required this.progress,
    required this.showButton,
    this.color,
    this.showLoadingIndicator = false,
    this.centerValue,
    this.centerUnit,
    this.subtitle,
    this.result,
    this.button,
    this.currentStep,
  });

  @override
  State<SpeedTestProgressIndicator> createState() => _SpeedTestProgressIndicatorState();
}

class _SpeedTestProgressIndicatorState extends State<SpeedTestProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _uploadAnimationController;
  late AnimationController _downloadAnimationController;
  late AnimationController _gridAnimationController;
  late Animation<double> _uploadProgressAnimation;
  late Animation<double> _downloadProgressAnimation;
  late Animation<double> _gridAnimation;
  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _uploadAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _uploadProgressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _uploadAnimationController, curve: Curves.easeInOut),
    );

    _downloadAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _downloadProgressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _downloadAnimationController, curve: Curves.easeInOut),
    );

    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _gridAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_gridAnimationController);

    _updateStepProgress();
  }

  @override
  void didUpdateWidget(SpeedTestProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress || oldWidget.currentStep != widget.currentStep) {
      _updateStepProgress();
    }
  }

  void _updateStepProgress() {
    if (widget.currentStep == SpeedTestStep.upload) {
      _uploadProgress = widget.progress;
      _downloadProgress = 0.0;
    } else if (widget.currentStep == SpeedTestStep.download) {
      _uploadProgress = 0.0;
      _downloadProgress = widget.progress;
    } else {
      _uploadProgress = widget.progress;
      _downloadProgress = widget.progress;
    }

    _updateUploadAnimation();
    _updateDownloadAnimation();
  }

  void _updateUploadAnimation() {
    final currentValue = _uploadProgressAnimation.value;
    final isDecreasing = _uploadProgress < currentValue;
    final duration = isDecreasing
        ? const Duration(milliseconds: 1200)
        : const Duration(milliseconds: 400);

    _uploadAnimationController.duration = duration;
    _uploadProgressAnimation = Tween<double>(begin: currentValue, end: _uploadProgress).animate(
      CurvedAnimation(
        parent: _uploadAnimationController,
        curve: isDecreasing ? Curves.easeOutCubic : Curves.easeInOut,
      ),
    );
    _uploadAnimationController.forward(from: 0.0);
  }

  void _updateDownloadAnimation() {
    final currentValue = _downloadProgressAnimation.value;
    final isDecreasing = _downloadProgress < currentValue;
    final duration = isDecreasing
        ? const Duration(milliseconds: 1200)
        : const Duration(milliseconds: 400);

    _downloadAnimationController.duration = duration;
    _downloadProgressAnimation = Tween<double>(begin: currentValue, end: _downloadProgress).animate(
      CurvedAnimation(
        parent: _downloadAnimationController,
        curve: isDecreasing ? Curves.easeOutCubic : Curves.easeInOut,
      ),
    );
    _downloadAnimationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _uploadAnimationController.dispose();
    _downloadAnimationController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_uploadProgressAnimation, _downloadProgressAnimation]),
      builder: (context, child) {
        return SizedBox(
          width: 320,
          height: 400,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Inner arc (upload)
              CustomPaint(
                size: const Size(230, 175),
                painter: SemicircularProgressPainter(
                  progress: _uploadProgress,
                  color: widget.color ?? AppColors.uploadColor,
                  strokeWidth: 2,
                  animation: _uploadProgressAnimation,
                  showStep: ProgressStep.upload,
                ),
              ),
              // Outer arc (download)
              CustomPaint(
                size: const Size(260, 175),
                painter: SemicircularProgressPainter(
                  progress: _downloadProgress,
                  color: widget.color ?? AppColors.downloadColor,
                  strokeWidth: 2,
                  animation: _downloadProgressAnimation,
                  showStep: ProgressStep.download,
                ),
              ),
              // Animated grid
              Positioned(
                top: 215,
                child: CustomPaint(
                  size: const Size(320, 45),
                  painter: AnimatedGridPainter(
                    animation: _gridAnimation,
                    strokeWidth: 1,
                  ),
                ),
              ),
              // Loading indicator
              if (widget.showLoadingIndicator)
                Positioned(
                  top: 130,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              // Center content (speed value)
              if (widget.centerValue != null && widget.centerUnit != null)
                Positioned(
                  top: 85,
                  child: _buildSpeedValueDisplay(),
                ),
              // Button
              if (widget.showButton && widget.button != null)
                Positioned(
                  top: widget.currentStep == null || widget.currentStep == SpeedTestStep.ready
                      ? 110
                      : 135,
                  child: widget.button!,
                ),
              // Metrics display
              if (widget.result != null &&
                  (widget.currentStep != SpeedTestStep.ready && widget.result!.ping > 0))
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: _buildMetricsDisplay(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedValueDisplay() {
    return Column(
      children: [
        if (widget.subtitle != null)
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 12,
              color: widget.color ?? AppColors.downloadColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 4),
        SizedBox(
          width: 140,
          height: 80,
          child: Center(
            child: Text(
              _formatSpeed(widget.centerValue!),
              style: TextStyle(
                fontSize: widget.centerValue! >= 100 ? 45 : 65,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
        ),
        Text(
          widget.centerUnit!,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  String _formatSpeed(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(0);
    } else if (value >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Widget _buildMetricsDisplay() {
    final result = widget.result!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricItem(
              label: 'DOWNLOAD',
              value: result.downloadSpeed,
              unit: 'Mbps',
              isLarge: true,
            ),
            const SizedBox(height: 8),
            _MetricItem(label: 'PING', value: result.ping.toDouble(), unit: 'ms'),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricItem(
              label: 'UPLOAD',
              value: result.uploadSpeed,
              unit: 'Mbps',
              isLarge: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MetricItemSmall(label: 'LATENCY', value: result.latency, unit: 'ms'),
                const SizedBox(width: 12),
                _MetricItemSmall(label: 'JITTER', value: result.jitter, unit: 'ms'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isLarge;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.unit,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        value > 0
            ? RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isLarge ? value.toStringAsFixed(1) : value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: isLarge ? 22 : 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            : Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
      ],
    );
  }
}

class _MetricItemSmall extends StatelessWidget {
  final String label;
  final int value;
  final String unit;

  const _MetricItemSmall({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(width: 4),
        Text(
          '$value $unit',
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
