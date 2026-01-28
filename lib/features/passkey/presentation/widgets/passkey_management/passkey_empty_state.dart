import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

/// Empty state widget shown when no passkeys are registered
class PasskeyEmptyState extends StatelessWidget {
  const PasskeyEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: AppColors.outline,
          style: BorderStyle.solid,
        ),
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
              Icons.fingerprint,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyLarge(
            'No Passkeys Yet',
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            'Add a passkey to enable quick sign-in with your biometrics',
            textAlign: TextAlign.center,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
