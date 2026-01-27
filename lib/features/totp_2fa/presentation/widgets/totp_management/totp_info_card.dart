import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class TotpInfoCard extends StatelessWidget {
  const TotpInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 24),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'What is Two-Factor Authentication?',
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText.bodySmall(
                  '2FA adds an extra layer of security by requiring a code from your authenticator app in addition to your password.',
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
