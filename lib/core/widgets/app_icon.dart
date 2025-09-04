import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_container.dart';

enum IconVariant {
  filled,
  outlined,
  ghost,
  gradient,
}

enum IconSize {
  small(16.0, 32.0),
  medium(24.0, 48.0),
  large(32.0, 64.0),
  extraLarge(48.0, 96.0);

  const IconSize(this.iconSize, this.containerSize);
  final double iconSize;
  final double containerSize;
}

class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.icon,
    this.variant = IconVariant.filled,
    this.size = IconSize.medium,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
  });

  factory AppIcon.filled({
    Key? key,
    required IconData icon,
    IconSize size = IconSize.medium,
    Color? color = Colors.white,
    Color? backgroundColor = AppColors.primary,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return AppIcon(
      key: key,
      icon: icon,
      variant: IconVariant.filled,
      size: size,
      color: color,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      onTap: onTap,
    );
  }

  factory AppIcon.outlined({
    Key? key,
    required IconData icon,
    IconSize size = IconSize.medium,
    Color? color = AppColors.primary,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return AppIcon(
      key: key,
      icon: icon,
      variant: IconVariant.outlined,
      size: size,
      color: color,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      onTap: onTap,
    );
  }

  factory AppIcon.ghost({
    Key? key,
    required IconData icon,
    IconSize size = IconSize.medium,
    Color? color = AppColors.primary,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return AppIcon(
      key: key,
      icon: icon,
      variant: IconVariant.ghost,
      size: size,
      color: color,
      backgroundColor: backgroundColor,
      onTap: onTap,
    );
  }

  factory AppIcon.gradient({
    Key? key,
    required IconData icon,
    IconSize size = IconSize.medium,
    Color? color = Colors.white,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return AppIcon(
      key: key,
      icon: icon,
      variant: IconVariant.gradient,
      size: size,
      color: color,
      borderRadius: borderRadius,
      onTap: onTap,
    );
  }

  final IconData icon;
  final IconVariant variant;
  final IconSize size;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      size: size.iconSize,
      color: color ?? _getDefaultColor(),
    );

    if (variant == IconVariant.ghost) {
      if (onTap != null) {
        return GestureDetector(
          onTap: onTap,
          child: iconWidget,
        );
      }
      return iconWidget;
    }

    return AppContainer(
      variant: _getContainerVariant(),
      width: size.containerSize,
      height: size.containerSize,
      color: backgroundColor ?? _getDefaultBackgroundColor(),
      borderRadius: borderRadius ?? BorderRadius.circular(size.containerSize / 4),
      onTap: onTap,
      alignment: Alignment.center,
      child: iconWidget,
    );
  }

  ContainerVariant _getContainerVariant() {
    switch (variant) {
      case IconVariant.filled:
        return ContainerVariant.surface;
      case IconVariant.outlined:
        return ContainerVariant.outlined;
      case IconVariant.ghost:
        return ContainerVariant.surface;
      case IconVariant.gradient:
        return ContainerVariant.gradient;
    }
  }

  Color _getDefaultColor() {
    switch (variant) {
      case IconVariant.filled:
      case IconVariant.gradient:
        return Colors.white;
      case IconVariant.outlined:
      case IconVariant.ghost:
        return AppColors.primary;
    }
  }

  Color? _getDefaultBackgroundColor() {
    switch (variant) {
      case IconVariant.filled:
        return AppColors.primary;
      case IconVariant.outlined:
        return Colors.transparent;
      case IconVariant.ghost:
        return null;
      case IconVariant.gradient:
        return null; // Will use gradient
    }
  }
}