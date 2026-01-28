import 'package:flutter/material.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/package_entity.dart';
import '../../bloc/tracking/tracking_cubit.dart';
import '../../bloc/tracking/tracking_state.dart';
import '../live_tracking_map.dart';
import 'map_loading.dart';
import 'map_error.dart';

class MapTab extends StatelessWidget {
  const MapTab({
    super.key,
    required this.package,
    required this.trackingCubit,
    required this.onStartTracking,
  });

  final PackageEntity package;
  final TrackingCubit trackingCubit;
  final void Function(PackageEntity) onStartTracking;

  @override
  Widget build(BuildContext context) {
    if (!trackingCubit.isTracking) {
      onStartTracking(package);
    }

    return BlocManager<TrackingCubit, BaseState<TrackingData>>(
      bloc: trackingCubit,
      showLoadingIndicator: false,
      showResultErrorNotifications: false,
      builder: (context, state) {
        final trackingData = state.data;

        return SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              if (trackingData != null)
                LiveTrackingMap(
                  trackingData: trackingData,
                  height: 350,
                )
              else if (state.isError)
                MapError(message: state.errorMessage ?? 'Unable to load tracking')
              else
                const MapLoading(),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppCard.elevated(
                child: Row(
                  children: [
                    AppContainer(
                      width: 48,
                      height: 48,
                      variant: ContainerVariant.filled,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.xl,
                      child: Icon(_getVehicleIcon(package.carrier.vehicleType), color: AppColors.primary),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.titleMedium('Current Location'),
                              AppText.bodyMedium('ETA: ${_formatETA(package.estimatedArrival)}', color: AppColors.primary),
                            ],
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: AppText.bodySmall(
                                  trackingData?.address ?? package.currentLocation?.name ?? 'Waiting for location...',
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              if (trackingData != null && trackingData.isLive) ...[
                                AppText.bodySmall(trackingData.formattedDistance, color: AppColors.primary),
                              ] else
                                AppText.bodySmall('${package.progress}% complete', color: AppColors.onSurfaceVariant),
                            ],
                          ),
                          if (trackingData != null && trackingData.isLive) ...[
                            AppSpacing.verticalSpacing(SpacingSize.xs),
                            Row(
                              children: [
                                Icon(Icons.speed, size: 14, color: AppColors.onSurfaceVariant),
                                AppSpacing.horizontalSpacing(SpacingSize.xs),
                                AppText.labelSmall(trackingData.formattedSpeed, color: AppColors.onSurfaceVariant),
                                AppSpacing.horizontalSpacing(SpacingSize.md),
                                Icon(Icons.update, size: 14, color: AppColors.onSurfaceVariant),
                                AppSpacing.horizontalSpacing(SpacingSize.xs),
                                AppText.labelSmall(trackingData.lastUpdateText, color: AppColors.onSurfaceVariant),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'plane':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  String _formatETA(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) return 'Overdue';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h ${difference.inMinutes % 60}m';
    return '${difference.inDays}d ${difference.inHours % 24}h';
  }
}
