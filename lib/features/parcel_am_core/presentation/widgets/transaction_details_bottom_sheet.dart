import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/app_spacing.dart';
import 'package:parcel_am/features/parcel_am_core/domain/repositories/withdrawal_repository.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
  final sl = GetIt.instance;

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
                padding: const EdgeInsets.all(20),
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
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
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
          color: Colors.grey[600],
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
          color: Colors.grey[600],
        ),
        AppSpacing.horizontalSpacing(SpacingSize.lg),
        Flexible(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppText.bodyMedium('Reference ID copied to clipboard', color: Colors.white),
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
                    color: Theme.of(context).primaryColor,
                    textAlign: TextAlign.right,
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.xs),
                Icon(
                  Icons.copy,
                  size: 16,
                  color: Theme.of(context).primaryColor,
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDetailRow(
              context,
              _formatMetadataKey(entry.key),
              entry.value.toString(),
            ),
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
        Navigator.of(context).pop();

        // Navigate to withdrawal detail screen
        try {
          final withdrawalRepo = sl<WithdrawalRepository>();
          final withdrawalOrder = await withdrawalRepo
              .getWithdrawalOrder(widget.transaction.referenceId!);

          if (context.mounted) {
            sl<NavigationService>().navigateTo(
              Routes.withdrawalTransactionDetail,
              arguments: {'withdrawalOrder': withdrawalOrder},
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium('Failed to load withdrawal details: $e', color: Colors.white),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
        return Colors.green.shade700;
      case 'withdrawal':
      case 'payment':
      case 'hold':
        return Colors.red.shade700;
      default:
        return Colors.black87;
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
    if (widget.transaction.status == null) return Colors.grey;

    switch (widget.transaction.status!.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
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
