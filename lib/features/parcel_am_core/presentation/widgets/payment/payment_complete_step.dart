import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_button.dart';

class PaymentCompleteStep extends StatelessWidget {
  const PaymentCompleteStep({
    super.key,
    required this.totalAmount,
    this.onTrackPackage,
    this.onMessageTraveler,
  });

  final String totalAmount;
  final VoidCallback? onTrackPackage;
  final VoidCallback? onMessageTraveler;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: EdgeInsets.only(bottom: SpacingSize.lg.value),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: AppRadius.pill,
          ),
          child: Icon(
            Icons.check_circle,
            color: AppColors.white,
            size: 40,
          ),
        ),
        AppText.headlineSmall(
          'Payment Secured!',
          fontWeight: FontWeight.bold,
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        AppText.bodyMedium(
          'Your $totalAmount has been successfully deposited into escrow',
          textAlign: TextAlign.center,
          color: AppColors.onSurfaceVariant,
        ),
        AppSpacing.verticalSpacing(SpacingSize.xxl),
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyLarge(
                'What\'s Next?',
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            'Waiting for traveler confirmation',
                            fontWeight: FontWeight.w500,
                          ),
                          AppText.bodySmall(
                            'You\'ll be notified when accepted',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            'Track your package',
                            fontWeight: FontWeight.w500,
                          ),
                          AppText.bodySmall(
                            'Real-time updates via SMS & app',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.xxl),
        Column(
          children: [
            AppButton.primary(
              onPressed: onTrackPackage,
              fullWidth: true,
              child: AppText.bodyLarge(
                'Track Package',
                color: AppColors.white,
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppButton.outline(
              onPressed: onMessageTraveler,
              fullWidth: true,
              child: AppText.bodyLarge(
                'Message Traveler',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
