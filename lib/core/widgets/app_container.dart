import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum ContainerVariant { surface, elevated, outlined, filled, gradient }

class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.variant = ContainerVariant.surface,
    this.color,
    this.borderRadius,
    this.gradient,
    this.border,
    this.shadows,
    this.onTap,
    this.alignment,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final ContainerVariant variant;
  final Color? color;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final AlignmentGeometry? alignment;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: decoration ?? _getDecoration(),
      child: child,
    );

    if (onTap != null) {
      container = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppRadius.lg,
        child: container,
      );
    }

    return container;
  }

  BoxDecoration _getDecoration() {
    switch (variant) {
      case ContainerVariant.surface:
        return BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: borderRadius ?? AppRadius.lg,
          border: border,
          boxShadow: shadows,
        );

      case ContainerVariant.elevated:
        return BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: borderRadius ?? AppRadius.lg,
          border: border,
          boxShadow:
              shadows ??
              [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
        );

      case ContainerVariant.outlined:
        return BoxDecoration(
          color: color ?? AppColors.transparent,
          borderRadius: borderRadius ?? AppRadius.lg,
          border: border ?? Border.all(color: AppColors.outline, width: 1),
          boxShadow: shadows,
        );

      case ContainerVariant.filled:
        return BoxDecoration(
          color: color ?? AppColors.surfaceVariant,
          borderRadius: borderRadius ?? AppRadius.lg,
          border: border,
          boxShadow: shadows,
        );

      case ContainerVariant.gradient:
        return BoxDecoration(
          gradient: gradient ?? AppColors.primaryGradient,
          borderRadius: borderRadius ?? AppRadius.lg,
          border: border,
          boxShadow: shadows,
        );
    }
  }
}
