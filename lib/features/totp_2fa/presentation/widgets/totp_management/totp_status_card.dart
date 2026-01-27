import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class TotpStatusCard extends StatelessWidget {
  const TotpStatusCard({
    super.key,
    required this.isEnabled,
    required this.isLoading,
  });

  final bool isEnabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnabled ? Icons.verified_user : Icons.shield_outlined,
              color: isEnabled ? AppColors.success : AppColors.warning,
              size: 24,
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'Status',
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isEnabled ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      isEnabled ? 'Enabled' : 'Not Enabled',
                      color: isEnabled ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
