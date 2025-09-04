import 'package:flutter/material.dart';
import 'app_container.dart';
import 'app_spacing.dart';

enum CardVariant {
  elevated,
  outlined,
  filled,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.padding = AppSpacing.paddingLG,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
    this.color,
  });

  factory AppCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = AppSpacing.paddingLG,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return AppCard(
      key: key,
      variant: CardVariant.elevated,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      borderRadius: borderRadius,
      color: color,
      child: child,
    );
  }

  factory AppCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = AppSpacing.paddingLG,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return AppCard(
      key: key,
      variant: CardVariant.outlined,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      borderRadius: borderRadius,
      color: color,
      child: child,
    );
  }

  factory AppCard.filled({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = AppSpacing.paddingLG,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return AppCard(
      key: key,
      variant: CardVariant.filled,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      borderRadius: borderRadius,
      color: color,
      child: child,
    );
  }

  final Widget child;
  final CardVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: _getContainerVariant(),
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      borderRadius: borderRadius,
      color: color,
      child: child,
    );
  }

  ContainerVariant _getContainerVariant() {
    switch (variant) {
      case CardVariant.elevated:
        return ContainerVariant.elevated;
      case CardVariant.outlined:
        return ContainerVariant.outlined;
      case CardVariant.filled:
        return ContainerVariant.filled;
    }
  }
}