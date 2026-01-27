import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class TotpEnableSection extends StatelessWidget {
  const TotpEnableSection({
    super.key,
    required this.isLoading,
    required this.onEnable,
  });

  final bool isLoading;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyLarge(
                'Protect Your Account',
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              AppText.bodyMedium(
                'Enable 2FA to add an extra layer of security to sensitive actions like releasing escrow funds.',
                textAlign: TextAlign.center,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        AppButton.primary(
          onPressed: isLoading ? null : onEnable,
          fullWidth: true,
          leadingIcon: const Icon(Icons.add, color: AppColors.white, size: 20),
          child: AppText.bodyMedium('Enable 2FA', color: AppColors.white),
        ),
      ],
    );
  }
}
