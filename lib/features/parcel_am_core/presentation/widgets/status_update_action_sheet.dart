import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../core/utils/app_utils.dart';
import '../../domain/entities/parcel_entity.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              const SizedBox(height: 16),

              // Task 3.4.2: Current status section
              _buildCurrentStatusSection(),
              const SizedBox(height: 24),

              // Task 3.4.4: Status progression indicator
              _buildStatusProgressionIndicator(),
              const SizedBox(height: 24),

              // Task 3.4.3: Next status action button
              _buildNextStatusButton(),
              const SizedBox(height: 12),

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
          borderRadius: BorderRadius.circular(2),
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
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.parcel.status.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.parcel.status.statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(widget.parcel.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
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
      ParcelStatus.delivered,
    ];

    final currentIndex = allStatuses.indexOf(widget.parcel.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Progress',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 12),
        // Status labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: allStatuses.map((status) {
            final index = allStatuses.indexOf(status);
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Text(
                _getShortStatusName(status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: isCompleted || isCurrent
                      ? status.statusColor
                      : AppColors.onSurfaceVariant,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
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
    final isDisabled = nextStatus == null || _isUpdating;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => _handleStatusUpdate(nextStatus),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: nextStatus?.statusColor ?? AppColors.primary,
          disabledBackgroundColor: AppColors.outline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUpdating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    nextStatus != null ? _getStatusIcon(nextStatus) : Icons.block,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nextStatus != null
                        ? 'Mark as ${nextStatus.displayName}'
                        : 'Already at Final Status',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Build cancel button
  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text(
        'Cancel',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
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
      // Task 3.4.6: Dispatch status update event
      if (!mounted) return;
      context.read<ParcelBloc>().add(
            ParcelUpdateStatusRequested(
              parcelId: widget.parcel.id,
              status: nextStatus,
            ),
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
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Status Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to mark this delivery as ${nextStatus.displayName}?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusDescription(nextStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticHelper.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticHelper.mediumImpact();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: nextStatus.statusColor,
            ),
            child: const Text('Confirm'),
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
        content: Text('Failed to update status: $errorMessage'),
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
