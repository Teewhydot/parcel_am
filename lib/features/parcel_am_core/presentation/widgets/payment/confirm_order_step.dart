import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';

class ConfirmOrderStep extends StatelessWidget {
  const ConfirmOrderStep({super.key, required this.packageDetails});

  final Map<String, String> packageDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Order Summary',
                variant: TextVariant.titleMedium,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: SpacingSize.massive.value,
                    height: SpacingSize.massive.value,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.md,
                    ),
                    child: const Icon(
                      Icons.description,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyLarge(
                          packageDetails['title']!,
                          fontWeight: FontWeight.w600,
                        ),
                        AppText.bodyMedium(
                          packageDetails['route']!,
                          color: AppColors.onSurfaceVariant,
                        ),
                        AppText.bodyMedium(
                          'Traveler: ${packageDetails['traveler']}',
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  AppText(
                    packageDetails['price']!,
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Price Breakdown',
                variant: TextVariant.titleMedium,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.bodyMedium(
                    'Delivery Fee',
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppText.bodyMedium(packageDetails['deliveryFee']!),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.bodyMedium(
                    'Service Fee',
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppText.bodyMedium(packageDetails['serviceFee']!),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    'Total',
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                  ),
                  AppText(
                    packageDetails['total']!,
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        Container(
          padding: AppSpacing.paddingLG,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.md,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield,
                color: AppColors.primary,
                size: 20,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(
                      'Escrow Protection',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    AppText.bodySmall(
                      'Your payment will be securely held until delivery is confirmed by both parties.',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
