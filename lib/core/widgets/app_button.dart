import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../helpers/haptic_helper.dart';
import '../services/auth/kyc_guard.dart';
import 'app_spacing.dart';
import 'kyc_blocked_action.dart';

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
     this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.large,
    this.fullWidth = false,
    this.loading = false,
    this.enabled = true,
    this.leadingIcon,
    this.trailingIcon,
    this.borderRadius,
    this.requiresKyc = false,
    this.kycBlockedAction = KycBlockedAction.showSnackbar,
  });

  factory AppButton.primary({
    Key? key,
     VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.large,
    bool fullWidth = false,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    BorderRadius? borderRadius,
    bool requiresKyc = false,
    KycBlockedAction kycBlockedAction = KycBlockedAction.showSnackbar,
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
      requiresKyc: requiresKyc,
      kycBlockedAction: kycBlockedAction,
      child: child,
    );
  }

  factory AppButton.secondary({
    Key? key,
     VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.large,
    bool fullWidth = false,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    BorderRadius? borderRadius,
    bool requiresKyc = false,
    KycBlockedAction kycBlockedAction = KycBlockedAction.showSnackbar,
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
      requiresKyc: requiresKyc,
      kycBlockedAction: kycBlockedAction,
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
    bool requiresKyc = false,
    KycBlockedAction kycBlockedAction = KycBlockedAction.showSnackbar,
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
      requiresKyc: requiresKyc,
      kycBlockedAction: kycBlockedAction,
      child: child,
    );
  }

  factory AppButton.text({
    Key? key,
     VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool requiresKyc = false,
    KycBlockedAction kycBlockedAction = KycBlockedAction.showSnackbar,
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
      requiresKyc: requiresKyc,
      kycBlockedAction: kycBlockedAction,
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
  final bool requiresKyc;
  final KycBlockedAction kycBlockedAction;

  VoidCallback? _wrapWithHaptic(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      HapticHelper.lightImpact();
      callback();
    };
  }

  /// Returns the appropriate callback based on KYC access status
  VoidCallback? _getKycAwareCallback(BuildContext context, bool hasKycAccess) {
    if (onPressed == null) return null;

    // If requires KYC and user doesn't have access, execute blocked action
    if (requiresKyc && !hasKycAccess) {
      return () {
        HapticHelper.lightImpact();
        kycBlockedAction.execute(context);
      };
    }

    // Otherwise, use the normal callback with haptic feedback
    return _wrapWithHaptic(onPressed);
  }

  @override
  Widget build(BuildContext context) {
    // If KYC protection is required, wrap with StreamBuilder for realtime monitoring
    if (requiresKyc) {
      return StreamBuilder<bool>(
        stream: context.watchKycAccess,
        builder: (context, snapshot) {
          final hasKycAccess = snapshot.data ?? false;
          return _buildButtonWidget(context, hasKycAccess);
        },
      );
    }

    // For non-KYC buttons, build normally
    return _buildButtonWidget(context, true);
  }

  Widget _buildButtonWidget(BuildContext context, bool hasKycAccess) {
    final isEnabled = enabled && !loading;

    Widget buttonChild = _buildButtonContent();
    Widget button = _buildButton(context, buttonChild, isEnabled, hasKycAccess);

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

  Widget _buildButton(
    BuildContext context,
    Widget buttonChild,
    bool isEnabled,
    bool hasKycAccess,
  ) {
    final effectiveCallback = _getKycAwareCallback(context, hasKycAccess);

    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadius.button,
            ),
            elevation: 0,
          ),
          child: buttonChild,
        );

      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadius.button,
            ),
            elevation: 0,
          ),
          child: buttonChild,
        );

      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: effectiveCallback,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadius.button,
            ),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          child: buttonChild,
        );
        
      case ButtonVariant.text:
        return TextButton(
          onPressed: effectiveCallback,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: size.padding,
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadius.sm,
            ),
          ),
          child: buttonChild,
        );

      case ButtonVariant.ghost:
        return InkWell(
          onTap: effectiveCallback,
          borderRadius: borderRadius ?? AppRadius.sm,
          child: Container(
            padding: size.padding,
            child: buttonChild,
          ),
        );

      case ButtonVariant.danger:
        return ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            padding: size.padding,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadius.button,
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
        return AppColors.white;
      case ButtonVariant.outline:
      case ButtonVariant.text:
      case ButtonVariant.ghost:
        return AppColors.primary;
    }
  }
}