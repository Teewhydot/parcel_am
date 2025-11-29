import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bloc/wallet/wallet_data.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildTransactionIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDate(transaction.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (transaction.referenceId != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${transaction.referenceId!.substring(0, 8)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_getAmountPrefix()}${_formatAmount(transaction.amount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getAmountColor(),
                      ),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon() {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;

    switch (transaction.type.toLowerCase()) {
      case 'deposit':
        iconData = Icons.arrow_downward;
        backgroundColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        break;
      case 'withdrawal':
        iconData = Icons.arrow_upward;
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red.shade700;
        break;
      case 'payment':
        iconData = Icons.shopping_cart;
        backgroundColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade700;
        break;
      case 'refund':
        iconData = Icons.refresh;
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        break;
      default:
        iconData = Icons.swap_horiz;
        backgroundColor = Colors.grey.shade50;
        iconColor = Colors.grey.shade700;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusChip() {
    if (transaction.status == null) return const SizedBox.shrink();

    Color chipColor;
    String statusText;

    switch (transaction.status!.toLowerCase()) {
      case 'completed':
      case 'success':
        chipColor = Colors.green;
        statusText = 'Completed';
        break;
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'failed':
      case 'expired':
        chipColor = Colors.red;
        statusText = 'Failed';
        break;
      case 'cancelled':
        chipColor = Colors.grey;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey;
        statusText = transaction.status!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: chipColor,
        ),
      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
