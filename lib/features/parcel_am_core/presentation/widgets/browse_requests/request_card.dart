import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../domain/entities/parcel_entity.dart';
import 'info_chip.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.parcel,
  });

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    final deliveryText = _getDeliveryText();
    final price = '₦${(parcel.price ?? 0.0).toStringAsFixed(0)}';
    final weight = '${parcel.weight ?? 0.0}kg';

    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        sl<NavigationService>().navigateTo(
          Routes.requestDetails,
          arguments: parcel.id,
        );
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.md,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText.bodyLarge(
                            parcel.category ?? 'Package',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppText(
                          price,
                          variant: TextVariant.titleMedium,
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      parcel.description ?? 'No description',
                      color: AppColors.onSurfaceVariant,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.xs),
              AppText.bodyMedium(parcel.route.origin),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              Container(
                width: 20,
                height: 1,
                color: AppColors.outline,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              const Icon(
                Icons.flag,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.xs),
              AppText.bodyMedium(parcel.route.destination),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoChip(icon: Icons.scale, label: 'Weight', value: weight),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    InfoChip(
                      icon: Icons.schedule,
                      label: 'Delivery',
                      value: deliveryText,
                    ),
                  ],
                ),
              ),
              if (parcel.sender.name.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.accent),
                    AppSpacing.horizontalSpacing(SpacingSize.xs),
                    AppText.bodyMedium(
                      parcel.sender.name.split(' ').first,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDeliveryText() {
    final deliveryDateStr = parcel.route.estimatedDeliveryDate;
    if (deliveryDateStr == null || deliveryDateStr.isEmpty) {
      return 'Flexible';
    }

    try {
      final deliveryDate = DateTime.parse(deliveryDateStr);
      final now = DateTime.now();
      final difference = deliveryDate.difference(now);

      if (difference.inHours < 24) {
        return 'Today ${DateFormat('h:mm a').format(deliveryDate)}';
      } else if (difference.inHours < 48) {
        return 'Tomorrow ${DateFormat('h:mm a').format(deliveryDate)}';
      } else {
        return DateFormat('MMM d, h:mm a').format(deliveryDate);
      }
    } catch (e) {
      return 'Flexible';
    }
  }
}
