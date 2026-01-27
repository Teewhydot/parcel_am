import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({
    super.key,
    required this.showPasswordReset,
  });

  final bool showPasswordReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLG,
      child: AppContainer(
        height: 192,
        variant: ContainerVariant.filled,
        borderRadius: AppRadius.lg,
        child: AppContainer(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AppContainer(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showPasswordReset ? Icons.lock_reset : Icons.email,
                      size: 48,
                      color: AppColors.white,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    Padding(
                      padding: AppSpacing.paddingMD,
                      child: AppText.bodyMedium(
                        showPasswordReset
                            ? 'Enter your email to receive a password reset link'
                            : 'Secure access with your email and password',
                        color: AppColors.white,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
