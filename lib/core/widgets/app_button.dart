import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../helpers/haptic_helper.dart';
import 'app_spacing.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  ghost,
  danger,
}

enum ButtonSize {
  small(EdgeInsets.symmetric(horizontal: 16, vertical: 8), 14.0),
  medium(EdgeInsets.symmetric(horizontal: 20, vertical: 12), 16.0),
  large(EdgeInsets.symmetric(horizontal: 24, vertical: 16), 18.0);

  const ButtonSize(this.padding, this.fontSize);
  final EdgeInsets padding;
  final double fontSize;
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.large,
    this.fullWidth = false,
    this.loading = false,
    this.enabled = true,
    this.leadingIcon,
    this.trailingIcon,
    this.borderRadius,
  });

  factory AppButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.large,
    bool fullWidth = false,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    BorderRadius? borderRadius,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      fullWidth: fullWidth,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      borderRadius: borderRadius,
      child: child,
    );
  }

  factory AppButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.large,
    bool fullWidth = false,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    BorderRadius? borderRadius,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      variant: ButtonVariant.secondary,
      size: size,
      fullWidth: fullWidth,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      borderRadius: borderRadius,
      child: child,
    );
  }

  factory AppButton.outline({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.large,
    bool fullWidth = false,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    BorderRadius? borderRadius,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      fullWidth: fullWidth,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      borderRadius: borderRadius,
      child: child,
    );
  }

  factory AppButton.text({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      variant: ButtonVariant.text,
      size: size,
      fullWidth: fullWidth,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: child,
    );
  }

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;
  final bool loading;
  final bool enabled;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final BorderRadius? borderRadius;

  VoidCallback? _wrapWithHaptic(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      HapticHelper.lightImpact();
      callback();
    };
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !loading && onPressed != null;

    Widget buttonChild = _buildButtonContent();
    Widget button = _buildButton(buttonChild, isEnabled);

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent() {
    List<Widget> children = [];
    
    if (loading) {
      children.add(SizedBox(
        width: size.fontSize,
        height: size.fontSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getContentColor()),
        ),
      ));
      children.add(AppSpacing.horizontalSpacing(SpacingSize.sm));
    } else if (leadingIcon != null) {
      children.add(leadingIcon!);
      children.add(AppSpacing.horizontalSpacing(SpacingSize.sm));
    }
    
    children.add(DefaultTextStyle(
      style: TextStyle(
        fontSize: size.fontSize,
        fontWeight: FontWeight.w600,
        color: _getContentColor(),
      ),
      child: child,
    ));
    
    if (!loading && trailingIcon != null) {
      children.add(AppSpacing.horizontalSpacing(SpacingSize.sm));
      children.add(trailingIcon!);
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildButton(Widget buttonChild, bool isEnabled) {
    final wrappedOnPressed = isEnabled ? _wrapWithHaptic(onPressed) : null;

    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: buttonChild,
        );

      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: buttonChild,
        );

      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: wrappedOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          child: buttonChild,
        );
        
      case ButtonVariant.text:
        return TextButton(
          onPressed: wrappedOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: size.padding,
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          ),
          child: buttonChild,
        );

      case ButtonVariant.ghost:
        return InkWell(
          onTap: wrappedOnPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Container(
            padding: size.padding,
            child: buttonChild,
          ),
        );

      case ButtonVariant.danger:
        return ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: buttonChild,
        );
    }
  }

  Color _getContentColor() {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.danger:
        return Colors.white;
      case ButtonVariant.outline:
      case ButtonVariant.text:
      case ButtonVariant.ghost:
        return AppColors.primary;
    }
  }
}