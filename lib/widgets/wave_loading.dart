import 'package:flutter/material.dart';

/// Default bar colour: white at ~85% opacity, matching the splash screen.
const Color _kBarColor = Color(0xD9FFFFFF);

/// The bouncing-bar "wave" loader from the splash screen, extracted into a
/// single reusable widget so every loading state in the app shares the same
/// look. It is fully self-contained — it owns its [AnimationController] — so it
/// can be dropped in anywhere a spinner used to live.
///
/// Defaults to **3 bars**, a trimmed-down version of the splash screen's 5-bar
/// wave. Use [WaveLoading.small] for the compact, in-button spots that used to
/// hold a tiny circular spinner.
class WaveLoading extends StatefulWidget {
  /// Colour of the bars.
  final Color color;

  /// How many bars to draw.
  final int barCount;

  /// Width of each bar.
  final double barWidth;

  /// Resting height of each bar.
  final double barHeight;

  /// Horizontal gap on each side of a bar.
  final double spacing;

  /// How far (in px) a bar travels up at the peak of its bounce.
  final double bounce;

  /// Per-bar phase offset as a fraction of the cycle (creates the wave).
  final double stagger;

  /// Duration of one full animation cycle.
  final Duration period;

  const WaveLoading({
    super.key,
    this.color = _kBarColor,
    this.barCount = 3,
    this.barWidth = 4,
    this.barHeight = 26,
    this.spacing = 3,
    this.bounce = 13,
    this.stagger = 0.15,
    this.period = const Duration(milliseconds: 1000),
  });

  /// Compact preset for inline / in-button use (replaces the small circular
  /// spinners that sat inside buttons and image placeholders).
  const WaveLoading.small({
    super.key,
    this.color = _kBarColor,
    this.barCount = 3,
  })  : barWidth = 2.6,
        barHeight = 12,
        spacing = 1.7,
        bounce = 6,
        stagger = 0.15,
        period = const Duration(milliseconds: 1000);

  @override
  State<WaveLoading> createState() => _WaveLoadingState();
}

class _WaveLoadingState extends State<WaveLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reserve room for the upward bounce and anchor the bars to the bottom, so
    // the wave never gets clipped even inside a tight, clipping parent.
    final boxHeight = widget.barHeight + widget.bounce;
    final radius = BorderRadius.circular(widget.barWidth * 0.5);

    return SizedBox(
      height: boxHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (index) {
              final progress =
                  (_controller.value + index * widget.stagger) % 1.0;
              final offset = progress < 0.5
                  ? -widget.bounce * (progress * 2)
                  : -widget.bounce * (2 - progress * 2);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.spacing),
                child: Transform.translate(
                  offset: Offset(0, offset),
                  child: Container(
                    width: widget.barWidth,
                    height: widget.barHeight,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: radius,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
