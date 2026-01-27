import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/parcel_entity.dart';
import 'info_tile.dart';

class AcceptConfirmationSheet extends StatelessWidget {
  const AcceptConfirmationSheet({
    super.key,
    required this.parcel,
    required this.onConfirm,
  });

  final ParcelEntity parcel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final deliveryDateStr = parcel.route.estimatedDeliveryDate;
    String deliveryText = 'Flexible';

    if (deliveryDateStr != null && deliveryDateStr.isNotEmpty) {
      try {
        final deliveryDate = DateTime.parse(deliveryDateStr);
        final now = DateTime.now();
        final difference = deliveryDate.difference(now);

        if (difference.inHours < 24) {
          deliveryText = 'Today ${DateFormat('h:mm a').format(deliveryDate)}';
        } else if (difference.inHours < 48) {
          deliveryText = 'Tomorrow ${DateFormat('h:mm a').format(deliveryDate)}';
        } else {
          deliveryText = DateFormat('MMM d, h:mm a').format(deliveryDate);
        }
      } catch (e) {
        deliveryText = 'Flexible';
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.topXxl,
      ),
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: AppRadius.xs,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),

              // Header
              Row(
                children: [
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.md,
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleMedium(
                          'Accept Delivery Request',
                          fontWeight: FontWeight.bold,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodySmall(
                          'Review the details before accepting',
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),

              // Route summary
              Container(
                padding: AppSpacing.paddingLG,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.md,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: AppSpacing.paddingXS,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: AppColors.white,
                            size: 6,
                          ),
                        ),
                        AppSpacing.horizontalSpacing(SpacingSize.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodySmall(
                                'Pickup',
                                color: AppColors.onSurfaceVariant,
                              ),
                              AppText.bodyMedium(
                                parcel.route.origin,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Container(
                        width: 2,
                        height: 20,
                        color: AppColors.outline,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: AppSpacing.paddingXS,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: AppColors.white,
                            size: 12,
                          ),
                        ),
                        AppSpacing.horizontalSpacing(SpacingSize.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodySmall(
                                'Deliver to',
                                color: AppColors.onSurfaceVariant,
                              ),
                              AppText.bodyMedium(
                                parcel.route.destination,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),

              // Details row
              Row(
                children: [
                  Expanded(
                    child: InfoTile(
                      icon: Icons.payments,
                      label: 'Earnings',
                      value: '₦${(parcel.price ?? 0.0).toStringAsFixed(0)}',
                      valueColor: AppColors.success,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: InfoTile(
                      icon: Icons.schedule,
                      label: 'Deliver by',
                      value: deliveryText,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),

              // Package info
              Row(
                children: [
                  Expanded(
                    child: InfoTile(
                      icon: Icons.category,
                      label: 'Category',
                      value: parcel.category ?? 'General',
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: InfoTile(
                      icon: Icons.scale,
                      label: 'Weight',
                      value: '${parcel.weight ?? 0.0}kg',
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),

              // Escrow notice
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      size: 20,
                      color: AppColors.info,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    Expanded(
                      child: AppText.bodySmall(
                        'Payment is secured in escrow and will be released upon delivery confirmation.',
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      onPressed: () => Navigator.of(context).pop(),
                      child: AppText.bodyMedium('Cancel'),
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      onPressed: onConfirm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.white,
                            size: 20,
                          ),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          AppText.bodyMedium(
                            'Accept Request',
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
