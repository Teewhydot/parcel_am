import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/package_entity.dart';
import 'activity_item.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({
    super.key,
    required this.activePackages,
  });

  final List<PackageEntity> activePackages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleLarge('Active Parcels', fontWeight: FontWeight.bold),
            AppButton.text(
              onPressed: () =>
                  sl<NavigationService>().navigateTo(Routes.browseRequests),
              child: AppText.labelMedium('View All'),
            ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        activePackages.isEmpty
            ? AppContainer(
                padding: AppSpacing.paddingXL,
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: AppColors.onSurfaceVariant,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    AppText.bodyMedium(
                      'No active parcels',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    activePackages.length > 5 ? 5 : activePackages.length,
                itemBuilder: (context, index) {
                  final package = activePackages[index];
                  final escrowStatus = package.paymentInfo != null &&
                          package.paymentInfo!.isEscrow
                      ? package.paymentInfo!.escrowStatus
                      : null;

                  return ActivityItem(
                    title: 'Package #${package.id.substring(0, 8)}',
                    subtitle: '${package.origin} → ${package.destination}',
                    status: _getStatusText(package.status),
                    statusColor: _getStatusColor(package.status),
                    icon: Icons.inventory_2_outlined,
                    hasAvatar: false,
                    avatarText: '',
                    escrowStatus: escrowStatus,
                    onTap: () {
                      sl<NavigationService>().navigateTo(
                        Routes.tracking,
                        arguments: {'packageId': package.id},
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'in_transit':
      case 'out_for_delivery':
        return AppColors.accent;
      case 'pending':
      case 'accepted':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
