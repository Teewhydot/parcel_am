import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../bloc/wallet/wallet_data.dart';

class TransactionDetailsBottomSheet extends StatelessWidget {
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
                    const SizedBox(height: 24),
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
                      _formatTransactionType(transaction.type),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Date',
                      DateFormat('MMM d, yyyy • hh:mm a').format(transaction.date),
                    ),
                    if (transaction.referenceId != null) ...[
                      const Divider(height: 24),
                      _buildCopyableDetailRow(
                        context,
                        'Reference ID',
                        transaction.referenceId!,
                      ),
                    ],
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Description',
                      transaction.description,
                    ),
                    if (transaction.metadata != null &&
                        transaction.metadata!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildMetadataSection(context),
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
          const SizedBox(height: 16),
          Text(
            'Transaction Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            '${_getAmountPrefix()}${_formatAmount(transaction.amount)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getAmountColor(),
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(),
              ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reference ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 4),
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
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...transaction.metadata!.entries.map((entry) {
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

  String _getAmountPrefix() {
    switch (transaction.type.toLowerCase()) {
      case 'deposit':
      case 'refund':
        return '+';
      case 'withdrawal':
      case 'payment':
        return '-';
      default:
        return '';
    }
  }

  Color _getAmountColor() {
    switch (transaction.type.toLowerCase()) {
      case 'deposit':
      case 'refund':
        return Colors.green.shade700;
      case 'withdrawal':
      case 'payment':
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
    if (transaction.status == null) return 'Unknown';

    switch (transaction.status!.toLowerCase()) {
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
        return transaction.status!;
    }
  }

  Color _getStatusColor() {
    if (transaction.status == null) return Colors.grey;

    switch (transaction.status!.toLowerCase()) {
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
