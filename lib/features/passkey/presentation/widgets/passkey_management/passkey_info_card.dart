import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

/// Info card explaining what passkeys are
class PasskeyInfoCard extends StatelessWidget {
  const PasskeyInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: AppRadius.md,
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 24,
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'What are Passkeys?',
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText(
                  'Passkeys replace passwords with secure biometric authentication. '
                  'Sign in with your fingerprint, face, or device screen lock.',
                  variant: TextVariant.bodySmall,
                  fontSize: AppFontSize.md,
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
