import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
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
            AppSpacing.horizontalSpacing(SpacingSize.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    transaction.description,
                    fontWeight: FontWeight.w500,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  Row(
                    children: [
                      AppText.bodySmall(
                        _formatDate(transaction.date),
                        color: AppColors.textSecondary,
                      ),
                      if (transaction.referenceId != null) ...[
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        AppText.bodySmall(
                          '• ${transaction.referenceId!.substring(0, 8)}',
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalSpacing(SpacingSize.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText.bodyMedium(
                  '${_getAmountPrefix()}${_formatAmount(transaction.amount)}',
                  fontWeight: FontWeight.w600,
                  color: _getAmountColor(),
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
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
        backgroundColor = AppColors.successLight;
        iconColor = AppColors.successDark;
        break;
      case 'withdrawal':
        iconData = Icons.arrow_upward;
        backgroundColor = AppColors.errorLight;
        iconColor = AppColors.errorDark;
        break;
      case 'payment':
        iconData = Icons.shopping_cart;
        backgroundColor = AppColors.infoLight;
        iconColor = AppColors.infoDark;
        break;
      case 'refund':
        iconData = Icons.refresh;
        backgroundColor = AppColors.warningLight;
        iconColor = AppColors.warningDark;
        break;
      default:
        iconData = Icons.swap_horiz;
        backgroundColor = AppColors.surfaceVariant;
        iconColor = AppColors.onSurfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.sm,
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
        chipColor = AppColors.success;
        statusText = 'Completed';
        break;
      case 'pending':
        chipColor = AppColors.pending;
        statusText = 'Pending';
        break;
      case 'failed':
      case 'expired':
        chipColor = AppColors.error;
        statusText = 'Failed';
        break;
      case 'cancelled':
        chipColor = AppColors.onSurfaceVariant;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = AppColors.onSurfaceVariant;
        statusText = transaction.status!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha:0.1),
        borderRadius: AppRadius.xs,
      ),
      child: AppText(
        statusText,
        variant: TextVariant.bodySmall,
        fontSize: AppFontSize.xs,
        fontWeight: FontWeight.w500,
        color: chipColor,
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
        return AppColors.successDark;
      case 'withdrawal':
      case 'payment':
        return AppColors.errorDark;
      default:
        return AppColors.onSurface;
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
