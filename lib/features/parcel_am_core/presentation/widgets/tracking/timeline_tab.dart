import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/package_entity.dart';

class TimelineTab extends StatelessWidget {
  const TimelineTab({super.key, required this.package});

  final PackageEntity package;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('Tracking Timeline'),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            ...package.trackingEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == package.trackingEvents.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getEventStatusColor(event.status),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getEventIcon(event.title),
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: AppColors.outline,
                          margin: EdgeInsets.symmetric(
                            vertical: AppSpacing.paddingXS.top / 2,
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(event.title, variant: TextVariant.titleSmall),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppText.labelSmall(_formatTime(event.timestamp)),
                                AppText.labelSmall(
                                  _formatDate(event.timestamp),
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodySmall(
                          event.description,
                          color: AppColors.onSurfaceVariant,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.onSurfaceVariant),
                            AppSpacing.horizontalSpacing(SpacingSize.xs),
                            AppText.labelSmall(
                              event.location,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        if (!isLast) AppSpacing.verticalSpacing(SpacingSize.md),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getEventStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'current':
        return AppColors.primary;
      case 'pending':
        return AppColors.onSurfaceVariant;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData _getEventIcon(String title) {
    if (title.contains('Delivered')) return Icons.check_circle;
    if (title.contains('Out for Delivery')) return Icons.local_shipping;
    if (title.contains('Arrived')) return Icons.flight_land;
    if (title.contains('Transit')) return Icons.flight;
    if (title.contains('Collected')) return Icons.inventory_2;
    return Icons.circle;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}
