import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/theme/app_colors.dart';
import 'package:parcel_am/core/theme/app_radius.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/app_spacing.dart';
import 'package:parcel_am/features/parcel_am_core/domain/repositories/withdrawal_repository.dart';
import 'package:parcel_am/injection_container.dart';
import '../bloc/wallet/wallet_data.dart';

class TransactionDetailsBottomSheet extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailsBottomSheet({
    super.key,
    required this.transaction,
  });

  static void show(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.topXl,
      ),
      builder: (context) => TransactionDetailsBottomSheet(
        transaction: transaction,
      ),
    );
  }

  @override
  State<TransactionDetailsBottomSheet> createState() =>
      _TransactionDetailsBottomSheetState();
}

class _TransactionDetailsBottomSheetState
    extends State<TransactionDetailsBottomSheet> {

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountSection(context),
                    AppSpacing.verticalSpacing(SpacingSize.xxl),
                    _buildDetailRow(
                      context,
                      'Status',
                      _getStatusText(),
                      valueColor: _getStatusColor(),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Transaction Type',
                      _formatTransactionType(widget.transaction.type),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Date',
                      DateFormat('MMM d, yyyy • hh:mm a')
                          .format(widget.transaction.date),
                    ),
                    if (widget.transaction.referenceId != null) ...[
                      const Divider(height: 24),
                      _buildCopyableDetailRow(
                        context,
                        'Reference ID',
                        widget.transaction.referenceId!,
                      ),
                    ],
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Description',
                      widget.transaction.description,
                    ),
                    if (widget.transaction.metadata != null &&
                        widget.transaction.metadata!.isNotEmpty) ...[
                      AppSpacing.verticalSpacing(SpacingSize.xxl),
                      _buildMetadataSection(context),
                    ],
                    // Add withdrawal details button for withdrawal transactions
                    if (widget.transaction.type.toLowerCase() == 'withdrawal' &&
                        widget.transaction.referenceId != null) ...[
                      AppSpacing.verticalSpacing(SpacingSize.xxl),
                      _buildViewWithdrawalDetailsButton(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.topXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: AppRadius.xs,
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText.titleLarge(
            'Transaction Details',
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          AppText(
            '${_getAmountPrefix()}${_formatAmount(widget.transaction.amount)}',
            variant: TextVariant.headlineSmall,
            fontWeight: FontWeight.bold,
            color: _getAmountColor(),
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          Container(
            padding: AppSpacing.paddingSM,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: AppRadius.xl,
            ),
            child: AppText.bodyMedium(
              _getStatusText(),
              fontWeight: FontWeight.w500,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bodyMedium(
          label,
          color: AppColors.textSecondary,
        ),
        AppSpacing.horizontalSpacing(SpacingSize.lg),
        Flexible(
          child: AppText.bodyMedium(
            value,
            fontWeight: FontWeight.w500,
            color: valueColor,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bodyMedium(
          label,
          color: AppColors.textSecondary,
        ),
        AppSpacing.horizontalSpacing(SpacingSize.lg),
        Flexible(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppText.bodyMedium('Reference ID copied to clipboard', color: AppColors.white),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText.bodyMedium(
                    value,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    textAlign: TextAlign.right,
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.xs),
                const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium(
          'Additional Information',
          fontWeight: FontWeight.w600,
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        ...widget.transaction.metadata!.entries.map((entry) {
          return Column(
            children: [
              _buildDetailRow(
              context,
              _formatMetadataKey(entry.key),
              entry.value.toString(),
            ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
            ],
          );
        }),
      ],
    );
  }

  /// Builds button to view full withdrawal details
  Widget _buildViewWithdrawalDetailsButton(BuildContext context) {
    return AppButton.outline(
      onPressed: () async {
        // Close the bottom sheet first
        sl<NavigationService>().goBack();

        // Navigate to withdrawal detail screen
        final withdrawalRepo = sl<WithdrawalRepository>();
        final result = await withdrawalRepo
            .getWithdrawalOrder(widget.transaction.referenceId!);

        result.fold(
          (failure) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppText.bodyMedium('Failed to load withdrawal details: ${failure.failureMessage}', color: AppColors.white),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          (withdrawalOrder) {
            if (context.mounted) {
              sl<NavigationService>().navigateTo(
                Routes.withdrawalTransactionDetail,
                arguments: {'withdrawalOrder': withdrawalOrder},
              );
            }
          },
        );
      },
      fullWidth: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_forward),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          AppText.bodyMedium('View Withdrawal Details'),
        ],
      ),
    );
  }

  String _getAmountPrefix() {
    switch (widget.transaction.type.toLowerCase()) {
      case 'deposit':
      case 'refund':
      case 'release':
        return '+';
      case 'withdrawal':
      case 'payment':
      case 'hold':
        return '-';
      default:
        return '';
    }
  }

  Color _getAmountColor() {
    switch (widget.transaction.type.toLowerCase()) {
      case 'deposit':
      case 'refund':
      case 'release':
        return AppColors.successDark;
      case 'withdrawal':
      case 'payment':
      case 'hold':
        return AppColors.errorDark;
      default:
        return AppColors.onSurface;
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '₦${formatter.format(amount)}';
  }

  String _getStatusText() {
    if (widget.transaction.status == null) return 'Unknown';

    switch (widget.transaction.status!.toLowerCase()) {
      case 'completed':
      case 'success':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
      case 'expired':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return widget.transaction.status!;
    }
  }

  Color _getStatusColor() {
    if (widget.transaction.status == null) return AppColors.onSurfaceVariant;

    switch (widget.transaction.status!.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'pending':
        return AppColors.pending;
      case 'failed':
      case 'expired':
        return AppColors.error;
      case 'cancelled':
        return AppColors.onSurfaceVariant;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _formatTransactionType(String type) {
    return type.substring(0, 1).toUpperCase() + type.substring(1).toLowerCase();
  }

  String _formatMetadataKey(String key) {
    return key
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }
}
