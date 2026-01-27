import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../domain/entities/parcel_entity.dart';
import 'detail_card.dart';

class ParcelDetailsContent extends StatelessWidget {
  const ParcelDetailsContent({super.key, required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    final deliveryDateStr = parcel.route.estimatedDeliveryDate;
    String deliveryText = 'Flexible';
    bool isUrgent = false;

    if (deliveryDateStr != null && deliveryDateStr.isNotEmpty) {
      try {
        final deliveryDate = DateTime.parse(deliveryDateStr);
        final now = DateTime.now();
        final difference = deliveryDate.difference(now);

        isUrgent = difference.inHours < 48;

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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgent Banner
          if (isUrgent)
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingLG,
              color: AppColors.error,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.white),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodyMedium(
                      'Urgent delivery needed by $deliveryText',
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.lg,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            parcel.category ?? 'Package',
                            variant: TextVariant.titleLarge,
                            fontSize: AppFontSize.xxl,
                            fontWeight: FontWeight.bold,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xs),
                          AppText.headlineSmall(
                            '₦${(parcel.price ?? 0.0).toStringAsFixed(0)}',
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xs),
                          AppText.bodySmall(
                            (parcel.escrowId != null && parcel.escrowId!.isNotEmpty)
                                ? 'Payment via escrow'
                                : 'Direct payment',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Package Description
                AppText.bodyLarge(
                  parcel.description ?? 'No description provided',
                  height: 1.5,
                ),

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Sender Info
                if (parcel.sender.name.isNotEmpty) ...[
                  AppText.bodyLarge(
                    'Sender',
                    fontWeight: FontWeight.bold,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20, color: AppColors.primary),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      AppText.bodyMedium(parcel.sender.name),
                    ],
                  ),
                  if (parcel.sender.phoneNumber.isNotEmpty) ...[
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20, color: AppColors.primary),
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        AppText.bodyMedium(parcel.sender.phoneNumber),
                      ],
                    ),
                  ],
                  AppSpacing.verticalSpacing(SpacingSize.xxl),
                ],

                // Route Info
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: AppSpacing.paddingSM,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.circle, color: AppColors.white, size: 8),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: AppColors.outline,
                        ),
                        Container(
                          padding: AppSpacing.paddingSM,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag, color: AppColors.white, size: 16),
                        ),
                      ],
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodySmall(
                            'From',
                            color: AppColors.onSurfaceVariant,
                          ),
                          AppText.bodyLarge(
                            parcel.route.origin,
                            fontWeight: FontWeight.w600,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xxl),
                          AppText.bodySmall(
                            'To',
                            color: AppColors.onSurfaceVariant,
                          ),
                          AppText.bodyLarge(
                            parcel.route.destination,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Package Details
                Row(
                  children: [
                    Expanded(
                      child: DetailCard(label: 'Weight', value: '${parcel.weight ?? 0.0}kg'),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: DetailCard(
                        label: 'Dimensions',
                        value: parcel.dimensions ?? 'Not specified',
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacing(SpacingSize.lg),

                Row(
                  children: [
                    Expanded(
                      child: DetailCard(
                        label: 'Deliver by',
                        value: deliveryText,
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Receiver Info
                AppText.bodyLarge(
                  'Receiver',
                  fontWeight: FontWeight.bold,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: AppColors.secondary),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(parcel.receiver.name),
                  ],
                ),
                if (parcel.receiver.phoneNumber.isNotEmpty) ...[
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: AppColors.secondary),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      AppText.bodyMedium(parcel.receiver.phoneNumber),
                    ],
                  ),
                ],
                if (parcel.receiver.address.isNotEmpty) ...[
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 20, color: AppColors.secondary),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      Expanded(
                        child: AppText.bodyMedium(parcel.receiver.address),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
    );
  }
}
