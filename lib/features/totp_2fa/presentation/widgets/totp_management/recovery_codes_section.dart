import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class RecoveryCodesSection extends StatelessWidget {
  const RecoveryCodesSection({
    super.key,
    required this.remainingCodes,
    required this.isLoading,
    required this.onRegenerate,
  });

  final int remainingCodes;
  final bool isLoading;
  final VoidCallback onRegenerate;

  bool get _isLow => remainingCodes <= 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                color: _isLow ? AppColors.warning : AppColors.onSurfaceVariant,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge(
                      'Recovery Codes',
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    AppText.bodyMedium(
                      '$remainingCodes codes remaining',
                      color: _isLow ? AppColors.warning : AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLow) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            Container(
              padding: AppSpacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodySmall(
                      'You have few recovery codes left. Consider generating new ones.',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppButton.outline(
            onPressed: isLoading ? null : onRegenerate,
            leadingIcon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
            child: AppText.bodyMedium('Generate New Codes', color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
