import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/parcel_entity.dart';
import '../bloc/parcel/parcel_cubit.dart';

/// Status Update Action Sheet
///
/// A modal bottom sheet for updating parcel delivery status.
///
/// Features:
/// - Displays current status with visual confirmation
/// - Shows next valid status in delivery progression
/// - Visual timeline of status progression
/// - Confirmation dialog before status update
/// - Loading states and error handling
/// - Haptic feedback for important actions
///
/// Task Group 3.4: Complete implementation of status update action sheet.
class StatusUpdateActionSheet extends StatefulWidget {
  final ParcelEntity parcel;

  const StatusUpdateActionSheet({
    super.key,
    required this.parcel,
  });

  /// Shows the status update action sheet as a modal bottom sheet.
  ///
  /// Returns a Future that completes when the sheet is dismissed.
  static Future<void> show(BuildContext context, ParcelEntity parcel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusUpdateActionSheet(parcel: parcel),
    );
  }

  @override
  State<StatusUpdateActionSheet> createState() => _StatusUpdateActionSheetState();
}

class _StatusUpdateActionSheetState extends State<StatusUpdateActionSheet> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.topXxl,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task 3.4.1: Drag handle
              _buildDragHandle(),
              AppSpacing.verticalSpacing(SpacingSize.lg),

              // Task 3.4.2: Current status section
              _buildCurrentStatusSection(),
              AppSpacing.verticalSpacing(SpacingSize.xxl),

              // Task 3.4.4: Status progression indicator
              _buildStatusProgressionIndicator(),
              AppSpacing.verticalSpacing(SpacingSize.xxl),

              // Task 3.4.3: Next status action button
              _buildNextStatusButton(),
              AppSpacing.verticalSpacing(SpacingSize.md),

              // Cancel button
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Task 3.4.1: Build drag handle indicator
  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.outline,
          borderRadius: AppRadius.xs,
        ),
      ),
    );
  }

  /// Task 3.4.2: Display current status section
  Widget _buildCurrentStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.parcel.status.statusColor.withValues(alpha: 0.1),
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: widget.parcel.status.statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Checkmark icon in circular background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.parcel.status.statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: widget.parcel.status.statusColor,
              size: 28,
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  'Current Status',
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText(
                  widget.parcel.status.displayName,
                  variant: TextVariant.titleLarge,
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.bold,
                  color: widget.parcel.status.statusColor,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText.bodySmall(
                  _getStatusDescription(widget.parcel.status),
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Task 3.4.4: Build status progression indicator
  Widget _buildStatusProgressionIndicator() {
    final allStatuses = [
      ParcelStatus.paid,
      ParcelStatus.pickedUp,
      ParcelStatus.inTransit,
      ParcelStatus.arrived,
      ParcelStatus.awaitingConfirmation,
      ParcelStatus.delivered,
    ];

    final currentIndex = allStatuses.indexOf(widget.parcel.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          'Delivery Progress',
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        Row(
          children: List.generate(
            allStatuses.length,
            (index) {
              final status = allStatuses[index];
              final isCompleted = index < currentIndex;
              final isCurrent = index == currentIndex;
              final isNext = index == currentIndex + 1;
              final isLast = index == allStatuses.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildProgressStep(
                        status: status,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isNext: isNext,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 2,
                          color: isCompleted || isCurrent
                              ? status.statusColor.withValues(alpha: 0.5)
                              : AppColors.outline,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        // Status labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: allStatuses.map((status) {
            final index = allStatuses.indexOf(status);
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: AppText(
                _getShortStatusName(status),
                variant: TextVariant.bodySmall,
                fontSize: AppFontSize.xxs,
                textAlign: TextAlign.center,
                color: isCompleted || isCurrent
                    ? status.statusColor
                    : AppColors.onSurfaceVariant,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build individual progress step indicator
  Widget _buildProgressStep({
    required ParcelStatus status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isNext,
  }) {
    Color dotColor;
    double dotSize;
    Widget? dotChild;

    if (isCompleted) {
      dotColor = status.statusColor;
      dotSize = 24;
      dotChild = Icon(
        Icons.check,
        size: 14,
        color: AppColors.white,
      );
    } else if (isCurrent) {
      dotColor = status.statusColor;
      dotSize = 28;
      dotChild = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
      );
    } else if (isNext) {
      dotColor = status.statusColor.withValues(alpha: 0.3);
      dotSize = 24;
    } else {
      dotColor = AppColors.outline;
      dotSize = 20;
    }

    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(
                color: status.statusColor.withValues(alpha: 0.4),
                width: 3,
              )
            : null,
      ),
      child: Center(child: dotChild),
    );
  }

  /// Task 3.4.3: Build next status action button
  Widget _buildNextStatusButton() {
    final nextStatus = widget.parcel.status.nextDeliveryStatus;
    final isDisabled = nextStatus == null;

    return AppButton.primary(
      onPressed: isDisabled ? null : () => _handleStatusUpdate(nextStatus),
      fullWidth: true,
      loading: _isUpdating,
      leadingIcon: !_isUpdating && nextStatus != null
          ? Icon(
              _getStatusIcon(nextStatus),
              size: 20,
              color: AppColors.white,
            )
          : null,
      child: AppText.bodyLarge(
        nextStatus != null
            ? 'Mark as ${nextStatus.displayName}'
            : 'Already at Final Status',
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  /// Build cancel button
  Widget _buildCancelButton() {
    return AppButton.text(
      onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
      child: AppText(
        'Cancel',
        variant: TextVariant.bodyMedium,
        fontSize: AppFontSize.lg,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Task 3.4.5 & 3.4.6: Handle status update with confirmation
  Future<void> _handleStatusUpdate(ParcelStatus nextStatus) async {
    // Trigger haptic feedback
    await HapticHelper.mediumImpact();

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(nextStatus);
    if (!confirmed) return;

    // Set updating state
    setState(() => _isUpdating = true);

    try {
      // Task 3.4.6: Dispatch status update
      if (!mounted) return;
      context.read<ParcelCubit>().updateParcelStatus(
            widget.parcel.id,
            nextStatus,
          );

      // Wait a brief moment for the update to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Show success haptic feedback
      await HapticHelper.success();

      // Dismiss action sheet on success
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success snackbar
      DFoodUtils.showSnackBar(
        'Status updated to ${nextStatus.displayName}',
        AppColors.success,
      );
    } catch (e) {
      // Show error haptic feedback
      await HapticHelper.error();

      // Show error snackbar with retry option
      if (!mounted) return;
      final shouldRetry = await _showErrorSnackbar(e.toString());

      if (shouldRetry) {
        // Retry the update
        await _handleStatusUpdate(nextStatus);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  /// Task 3.4.5: Show confirmation dialog before status update
  Future<bool> _showConfirmationDialog(ParcelStatus nextStatus) async {
    await HapticHelper.lightImpact();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: AppText.titleMedium('Confirm Status Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Are you sure you want to mark this delivery as ${nextStatus.displayName}?',
              variant: TextVariant.bodyMedium,
              fontSize: AppFontSize.lg,
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodySmall(
                      _getStatusDescription(nextStatus),
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton.text(
            onPressed: () {
              HapticHelper.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: AppText.bodyMedium('Cancel'),
          ),
          AppButton.primary(
            onPressed: () {
              HapticHelper.mediumImpact();
              Navigator.of(context).pop(true);
            },
            child: AppText.bodyMedium('Confirm', color: AppColors.white),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Task 3.4.6: Show error snackbar with retry option
  Future<bool> _showErrorSnackbar(String errorMessage) async {
    if (!mounted) return false;

    await HapticHelper.error();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final snackBarController = scaffoldMessenger.showSnackBar(
      SnackBar(
        content: AppText.bodyMedium('Failed to update status: $errorMessage', color: AppColors.white),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: AppColors.white,
          onPressed: () {
            // Return value will be true when retry is pressed
          },
        ),
      ),
    );

    final result = await snackBarController.closed;
    return result == SnackBarClosedReason.action;
  }

  // Helper methods

  /// Get brief description for each status
  String _getStatusDescription(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.paid:
        return 'Payment confirmed, awaiting pickup';
      case ParcelStatus.pickedUp:
        return 'Package collected from sender';
      case ParcelStatus.inTransit:
        return 'Package is on the way';
      case ParcelStatus.arrived:
        return 'Package has reached destination';
      case ParcelStatus.awaitingConfirmation:
        return 'Waiting for sender to confirm delivery & release payment';
      case ParcelStatus.delivered:
        return 'Package successfully delivered';
      case ParcelStatus.cancelled:
        return 'Delivery has been cancelled';
      case ParcelStatus.disputed:
        return 'Delivery is under dispute';
      default:
        return 'Package is being processed';
    }
  }

  /// Get short status name for timeline labels
  String _getShortStatusName(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.paid:
        return 'Paid';
      case ParcelStatus.pickedUp:
        return 'Picked Up';
      case ParcelStatus.inTransit:
        return 'In Transit';
      case ParcelStatus.arrived:
        return 'Arrived';
      case ParcelStatus.awaitingConfirmation:
        return 'Confirm';
      case ParcelStatus.delivered:
        return 'Delivered';
      default:
        return status.displayName;
    }
  }

  /// Get icon for each status
  IconData _getStatusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.paid:
        return Icons.payment;
      case ParcelStatus.pickedUp:
        return Icons.shopping_bag;
      case ParcelStatus.inTransit:
        return Icons.local_shipping;
      case ParcelStatus.arrived:
        return Icons.place;
      case ParcelStatus.awaitingConfirmation:
        return Icons.hourglass_empty;
      case ParcelStatus.delivered:
        return Icons.check_circle;
      case ParcelStatus.cancelled:
        return Icons.cancel;
      case ParcelStatus.disputed:
        return Icons.report_problem;
      default:
        return Icons.info;
    }
  }
}
