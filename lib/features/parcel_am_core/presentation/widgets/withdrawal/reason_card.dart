import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class FailureReasonCard extends StatelessWidget {
  const FailureReasonCard({
    super.key,
    required this.reason,
  });

  final String reason;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      color: AppColors.error.withValues(alpha: 0.05),
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              const AppText(
                'Failure Reason',
                variant: TextVariant.titleSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            reason,
            color: AppColors.onSurface,
          ),
        ],
      ),
    );
  }
}

class ReversalReasonCard extends StatelessWidget {
  const ReversalReasonCard({
    super.key,
    required this.reason,
  });

  final String reason;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      color: AppColors.pendingLight,
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.pendingDark,
                size: 20,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              const AppText(
                'Reversal Reason',
                variant: TextVariant.titleSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.pendingDark,
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            reason,
            color: AppColors.onSurface,
          ),
        ],
      ),
    );
  }
}
