import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection_container.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_spacing.dart';

/// My Packages tab showing parcels created by the current user (as sender).
///
/// Features:
/// - Status filter dropdown (All, Active, Delivered, Cancelled)
/// - Pull-to-refresh functionality
/// - Empty state when no packages
/// - Animated list of package cards
/// - Navigate to parcel details on tap
class MyPackagesTab extends StatefulWidget {
  const MyPackagesTab({super.key});

  @override
  State<MyPackagesTab> createState() => _MyPackagesTabState();
}

class _MyPackagesTabState extends State<MyPackagesTab> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Active', 'Delivered', 'Cancelled'];
  String? _confirmingParcelId;

  List<ParcelEntity> _filterParcels(List<ParcelEntity> parcels) {
    switch (_selectedFilter) {
      case 'Active':
        return parcels.where((p) =>
          p.status == ParcelStatus.created ||
          p.status == ParcelStatus.paid ||
          p.status == ParcelStatus.inTransit ||
          p.status == ParcelStatus.pickedUp ||
          p.status == ParcelStatus.arrived ||
          p.status == ParcelStatus.awaitingConfirmation
        ).toList();
      case 'Delivered':
        return parcels.where((p) => p.status == ParcelStatus.delivered).toList();
      case 'Cancelled':
        return parcels.where((p) =>
          p.status == ParcelStatus.cancelled ||
          p.status == ParcelStatus.disputed
        ).toList();
      case 'All':
      default:
        return parcels;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParcelBloc, BaseState<ParcelData>>(
      builder: (context, state) {
        if (state is AsyncLoadingState<ParcelData> && state.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AsyncErrorState<ParcelData>) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                AppText(
                  'Failed to load packages',
                  variant: TextVariant.titleMedium,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w600,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                AppText.bodyMedium(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          );
        }

        final userParcels = state.data?.userParcels ?? [];

        if (userParcels.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No packages yet',
            subtitle: 'Packages you create will appear here',
          );
        }

        final filteredParcels = _filterParcels(userParcels);

        return Column(
          children: [
            _buildStatusFilter(),
            if (filteredParcels.isEmpty)
              Expanded(
                child: _buildEmptyState(
                  icon: Icons.filter_list_off,
                  title: 'No $_selectedFilter packages',
                  subtitle: 'Try selecting a different filter',
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppText.bodyMedium(
                    '${filteredParcels.length} package${filteredParcels.length == 1 ? '' : 's'}',
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 100,
                      ),
                      itemCount: filteredParcels.length,
                      itemBuilder: (context, index) {
                        final parcel = filteredParcels[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildPackageCard(parcel),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 20, color: AppColors.onSurfaceVariant),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            'Filter:',
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.sm,
              ),
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: const SizedBox(),
                items: _filterOptions.map((filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: AppText.bodyMedium(filter, fontWeight: FontWeight.w500),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFilter = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(ParcelEntity parcel) {
    final statusColor = _getStatusColor(parcel.status);
    final price = '₦${(parcel.price ?? 0.0).toStringAsFixed(0)}';

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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(parcel.status),
                  color: statusColor,
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
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: AppRadius.xs,
                      ),
                      child: AppText.bodySmall(
                        parcel.status.displayName,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.onSurfaceVariant),
              AppSpacing.horizontalSpacing(SpacingSize.xs),
              Expanded(
                child: AppText.bodyMedium(
                  parcel.route.origin,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(width: 20, height: 1, color: AppColors.outline),
              AppSpacing.horizontalSpacing(SpacingSize.xs),
              const Icon(Icons.flag, size: 16, color: AppColors.onSurfaceVariant),
              AppSpacing.horizontalSpacing(SpacingSize.xs),
              Expanded(
                child: AppText.bodyMedium(
                  parcel.route.destination,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (parcel.travelerName != null) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.accent),
                AppSpacing.horizontalSpacing(SpacingSize.xs),
                AppText.bodySmall(
                  'Courier: ${parcel.travelerName}',
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ],
          // Show Confirm Delivery button for parcels awaiting confirmation
          if (parcel.status == ParcelStatus.awaitingConfirmation) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppButton.primary(
              loading: _confirmingParcelId == parcel.id,
              onPressed: _confirmingParcelId == parcel.id
                  ? null
                  : () => _confirmDelivery(parcel),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 20, color: Colors.white),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  AppText.labelMedium('Confirm Delivery', color: Colors.white),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelivery(ParcelEntity parcel) {
    if (parcel.escrowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to confirm delivery: Missing escrow information'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _confirmingParcelId = parcel.id);

    context.read<ParcelBloc>().add(
      ParcelConfirmDeliveryRequested(
        parcelId: parcel.id,
        escrowId: parcel.escrowId!,
      ),
    );

    // Reset loading state after a delay (the bloc will update the parcel status)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _confirmingParcelId == parcel.id) {
        setState(() => _confirmingParcelId = null);
      }
    });
  }

  Color _getStatusColor(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return AppColors.onSurfaceVariant;
      case ParcelStatus.paid:
        return AppColors.info;
      case ParcelStatus.inTransit:
      case ParcelStatus.pickedUp:
      case ParcelStatus.arrived:
        return AppColors.primary;
      case ParcelStatus.awaitingConfirmation:
        return AppColors.warning;
      case ParcelStatus.delivered:
        return AppColors.success;
      case ParcelStatus.cancelled:
      case ParcelStatus.disputed:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return Icons.pending_outlined;
      case ParcelStatus.paid:
        return Icons.payment;
      case ParcelStatus.inTransit:
        return Icons.local_shipping;
      case ParcelStatus.pickedUp:
        return Icons.inventory;
      case ParcelStatus.arrived:
        return Icons.place;
      case ParcelStatus.awaitingConfirmation:
        return Icons.hourglass_bottom;
      case ParcelStatus.delivered:
        return Icons.check_circle;
      case ParcelStatus.cancelled:
        return Icons.cancel;
      case ParcelStatus.disputed:
        return Icons.warning;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.onSurfaceVariant),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText(
            title,
            variant: TextVariant.titleMedium,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            subtitle,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
