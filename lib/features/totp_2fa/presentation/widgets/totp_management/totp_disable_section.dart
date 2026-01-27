import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class TotpDisableSection extends StatelessWidget {
  const TotpDisableSection({
    super.key,
    required this.isLoading,
    required this.onDisable,
  });

  final bool isLoading;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.bodyLarge(
            'Disable 2FA',
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodyMedium(
            'This will make your account less secure. You will no longer need to verify for sensitive actions.',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppButton.outline(
            onPressed: isLoading ? null : onDisable,
            child: AppText.bodyMedium('Disable 2FA', color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
