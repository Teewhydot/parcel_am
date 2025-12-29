import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import 'delivery_card.dart';

/// My Deliveries tab showing parcels accepted by the current user as courier.
///
/// Features:
/// - Status filter dropdown (All, Active, Completed)
/// - Pull-to-refresh functionality
/// - Empty state when no deliveries
/// - Animated list of delivery cards
/// - Status update action via delivery card button
/// - Skeleton loaders for improved UX during loading (Task 3.6.3)
class MyDeliveriesTab extends StatefulWidget {
  const MyDeliveriesTab({super.key});

  @override
  State<MyDeliveriesTab> createState() => _MyDeliveriesTabState();
}

class _MyDeliveriesTabState extends State<MyDeliveriesTab> {
  // Status filter options
  String _selectedFilter = 'All'; // Options: All, Active, Completed
  final List<String> _filterOptions = ['All', 'Active', 'Completed'];

  /// Applies the selected filter to the accepted parcels list
  List<ParcelEntity> _filterParcels(ParcelData data) {
    switch (_selectedFilter) {
      case 'Active':
        return data.activeParcels;
      case 'Completed':
        return data.completedParcels;
      case 'All':
      default:
        return data.acceptedParcels;
    }
  }

  /// Handles status update button press
  /// Opens status update action sheet
  void _handleUpdateStatus(ParcelEntity parcel) {
    final currentStatus = parcel.status;
    final nextStatus = currentStatus.nextDeliveryStatus;

    if (nextStatus == null || !currentStatus.canProgressToNextStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText.bodyMedium(
            'Cannot update status from ${currentStatus.displayName}',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.topLg,
      ),
      builder: (context) => _StatusUpdateBottomSheet(
        parcel: parcel,
        currentStatus: currentStatus,
        nextStatus: nextStatus,
        onConfirm: () {
          context.read<ParcelBloc>().add(
            ParcelUpdateStatusRequested(
              parcelId: parcel.id,
              status: nextStatus,
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParcelBloc, BaseState<ParcelData>>(
      builder: (context, state) {
        // Task 3.6.3: Show loading skeletons while data is being fetched
        if (state is AsyncLoadingState<ParcelData> && state.data == null) {
          return Column(
            children: [
              // Status filter skeleton
              _buildStatusFilter(),
              // Loading skeleton cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3, // Show 3 skeleton cards
                  itemBuilder: (context, index) {
                    return const DeliveryCardSkeleton();
                  },
                ),
              ),
            ],
          );
        }

        // Handle error state
        if (state is AsyncErrorState<ParcelData>) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                AppText(
                  'Failed to load deliveries',
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
                AppSpacing.verticalSpacing(SpacingSize.xxl),
                AppButton.primary(
                  onPressed: () {
                    // Retry loading accepted parcels
                    // Note: Would need userId from auth context
                  },
                  child: AppText.bodyMedium('Retry', color: AppColors.white),
                ),
              ],
            ),
          );
        }

        // Get accepted parcels from state
        final data = state.data ?? const ParcelData();
        final acceptedParcels = data.acceptedParcels;

        // Show empty state if no accepted deliveries at all
        if (acceptedParcels.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No active deliveries',
            subtitle: 'Accepted requests will appear here',
          );
        }

        // Apply filter to parcels
        final filteredParcels = _filterParcels(data);

        // Build main content with filter and list
        return Column(
          children: [
            // Status filter dropdown
            _buildStatusFilter(),

            // Show empty state for filtered results
            if (filteredParcels.isEmpty)
              Expanded(
                child: _buildEmptyState(
                  icon: Icons.filter_list_off,
                  title: 'No $_selectedFilter deliveries',
                  subtitle: 'Try selecting a different filter',
                ),
              )
            else
              // Deliveries count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppText.bodyMedium(
                    '${filteredParcels.length} delivery${filteredParcels.length == 1 ? '' : 'ies'}',
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),

            // Deliveries list with pull-to-refresh and animations
            // Task 3.6.1: Staggered animations already implemented
            if (filteredParcels.isNotEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Re-fetch accepted parcels
                    // Note: Would need userId from auth context
                    // For now, just add a small delay to show the refresh indicator
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredParcels.length,
                      itemBuilder: (context, index) {
                        final parcel = filteredParcels[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: DeliveryCard(
                                parcel: parcel,
                                onUpdateStatus: () => _handleUpdateStatus(parcel),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Builds the status filter dropdown
  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
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
                    child: AppText.bodyMedium(
                      filter,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an empty state widget with custom icon, title, and subtitle
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
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

/// Bottom sheet for confirming status update
class _StatusUpdateBottomSheet extends StatelessWidget {
  final ParcelEntity parcel;
  final ParcelStatus currentStatus;
  final ParcelStatus nextStatus;
  final VoidCallback onConfirm;

  const _StatusUpdateBottomSheet({
    required this.parcel,
    required this.currentStatus,
    required this.nextStatus,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          AppSpacing.verticalSpacing(SpacingSize.xxl),
          AppText(
            'Update Delivery Status',
            variant: TextVariant.titleLarge,
            fontSize: AppFontSize.xxl,
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.md,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            'Current: ${currentStatus.displayName}',
                            color: AppColors.onSurfaceVariant,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xs),
                          AppText.bodyLarge(
                            'Next: ${nextStatus.displayName}',
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
          AppText.bodyMedium(
            'Package: ${parcel.category ?? 'Package'} #${parcel.id.substring(0, 8)}',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xxl),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  onPressed: () => Navigator.pop(context),
                  child: AppText.bodyMedium('Cancel', color: AppColors.primary),
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.lg),
              Expanded(
                child: AppButton.primary(
                  onPressed: onConfirm,
                  child: AppText.bodyMedium(
                    'Confirm',
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
        ],
      ),
    );
  }
}
