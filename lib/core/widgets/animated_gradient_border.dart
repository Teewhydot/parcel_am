import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A widget that wraps its child with an animated gradient border.
/// Used for highlighting ongoing/active deliveries with visual feedback.
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final Duration duration;
  final List<Color>? gradientColors;
  final bool enabled;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.5,
    this.borderRadius = 16,
    this.duration = const Duration(seconds: 2),
    this.gradientColors,
    this.enabled = true,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final colors =
        widget.gradientColors ??
        [
          AppColors.primary,
          AppColors.info,
          AppColors.success,
          AppColors.warning,
          AppColors.primary,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: 6.28318, // 2 * pi
              transform: GradientRotation(_controller.value * 6.28318),
              colors: colors,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius - widget.borderWidth,
                ),
                color: Theme.of(context).cardColor,
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
