import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/theme/app_colors.dart';
import 'package:parcel_am/core/widgets/app_spacing.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/withdrawal_order_entity.dart';

/// Screen displaying detailed information about a withdrawal transaction
///
/// This screen shows:
/// - Withdrawal amount and status
/// - Bank account details
/// - Timeline of withdrawal processing
/// - Failure or reversal reasons (if applicable)
/// - Option to retry failed withdrawals
class WithdrawalTransactionDetailScreen extends StatelessWidget {
  final WithdrawalOrderEntity withdrawalOrder;
  final sl = GetIt.instance;

  WithdrawalTransactionDetailScreen({
    super.key,
    required this.withdrawalOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Details'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountCard(context),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            _buildStatusTimeline(context),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            _buildBankAccountCard(context),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            _buildDetailsCard(context),
            if (withdrawalOrder.failureReason != null) ...[
              AppSpacing.verticalSpacing(SpacingSize.lg),
              _buildFailureReasonCard(context),
            ],
            if (withdrawalOrder.reversalReason != null) ...[
              AppSpacing.verticalSpacing(SpacingSize.lg),
              _buildReversalReasonCard(context),
            ],
            AppSpacing.verticalSpacing(SpacingSize.xxl),
            if (withdrawalOrder.status == WithdrawalStatus.failed)
              _buildRetryButton(context),
          ],
        ),
      ),
    );
  }

  /// Builds the amount display card
  Widget _buildAmountCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingXXL,
        child: Column(
          children: [
            Text(
              'Withdrawal Amount',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            Text(
              '₦${_formatAmount(withdrawalOrder.amount)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            _buildStatusChip(context),
          ],
        ),
      ),
    );
  }

  /// Builds the status chip badge
  Widget _buildStatusChip(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusInfo['color']),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo['icon'],
            size: 16,
            color: statusInfo['color'],
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo['text'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusInfo['color'],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the status timeline showing withdrawal progress
  Widget _buildStatusTimeline(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            _buildTimelineItem(
              context,
              'Initiated',
              _formatDateTime(withdrawalOrder.createdAt),
              isCompleted: true,
            ),
            _buildTimelineItem(
              context,
              'Processing',
              withdrawalOrder.status != WithdrawalStatus.pending
                  ? _formatDateTime(withdrawalOrder.updatedAt)
                  : 'Waiting...',
              isCompleted: withdrawalOrder.status != WithdrawalStatus.pending,
              isActive: withdrawalOrder.status == WithdrawalStatus.processing,
            ),
            _buildTimelineItem(
              context,
              _getFinalStepLabel(),
              withdrawalOrder.processedAt != null
                  ? _formatDateTime(withdrawalOrder.processedAt!)
                  : 'Pending...',
              isCompleted: withdrawalOrder.status == WithdrawalStatus.success ||
                  withdrawalOrder.status == WithdrawalStatus.failed ||
                  withdrawalOrder.status == WithdrawalStatus.reversed,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual timeline item
  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    String timestamp, {
    bool isCompleted = false,
    bool isActive = false,
    bool isLast = false,
  }) {
    final color = isCompleted
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.onSurfaceVariant.withOpacity(0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive ? color : Colors.transparent,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted || isActive
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timestamp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bank account information card
  Widget _buildBankAccountCard(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            _buildDetailRow(
              context,
              'Account Name',
              withdrawalOrder.bankAccount.accountName,
            ),
            const Divider(height: 20),
            _buildDetailRow(
              context,
              'Account Number',
              _maskAccountNumber(withdrawalOrder.bankAccount.accountNumber),
            ),
            const Divider(height: 20),
            _buildDetailRow(
              context,
              'Bank',
              withdrawalOrder.bankAccount.bankName,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the transaction details card
  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            _buildCopyableDetailRow(
              context,
              'Reference ID',
              withdrawalOrder.id,
            ),
            const Divider(height: 20),
            _buildDetailRow(
              context,
              'Created',
              _formatDateTime(withdrawalOrder.createdAt),
            ),
            const Divider(height: 20),
            _buildDetailRow(
              context,
              'Last Updated',
              _formatDateTime(withdrawalOrder.updatedAt),
            ),
            if (withdrawalOrder.processedAt != null) ...[
              const Divider(height: 20),
              _buildDetailRow(
                context,
                'Processed',
                _formatDateTime(withdrawalOrder.processedAt!),
              ),
            ],
            if (withdrawalOrder.transferCode != null) ...[
              const Divider(height: 20),
              _buildCopyableDetailRow(
                context,
                'Transfer Code',
                withdrawalOrder.transferCode!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the failure reason card
  Widget _buildFailureReasonCard(BuildContext context) {
    return Card(
      elevation: 1,
      color: AppColors.error.withOpacity(0.05),
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Failure Reason',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                ),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            Text(
              withdrawalOrder.failureReason!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the reversal reason card
  Widget _buildReversalReasonCard(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.orange.shade50,
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reversal Reason',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                ),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            Text(
              withdrawalOrder.reversalReason!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a detail row
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Builds a copyable detail row with copy icon
  Widget _buildCopyableDetailRow(
      BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
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
                          color: AppColors.primary,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 4),
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

  /// Builds retry button for failed withdrawals
  Widget _buildRetryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to withdrawal screen with pre-filled data
          sl<NavigationService>().navigateTo(
            Routes.withdrawal,
            arguments: {
              'prefillAmount': withdrawalOrder.amount,
              'prefillBankAccount': withdrawalOrder.bankAccount,
              'originalReference': withdrawalOrder.id,
            },
          );
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Retry Withdrawal'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Formats amount with thousands separator
  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  /// Formats DateTime to readable string
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • hh:mm a').format(dateTime);
  }

  /// Masks account number to show only last 4 digits
  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return '******${accountNumber.substring(accountNumber.length - 4)}';
  }

  /// Gets status information (color, icon, text)
  Map<String, dynamic> _getStatusInfo() {
    switch (withdrawalOrder.status) {
      case WithdrawalStatus.pending:
        return {
          'color': Colors.orange,
          'icon': Icons.pending_outlined,
          'text': 'Pending',
        };
      case WithdrawalStatus.processing:
        return {
          'color': AppColors.primary,
          'icon': Icons.hourglass_empty,
          'text': 'Processing',
        };
      case WithdrawalStatus.success:
        return {
          'color': AppColors.success,
          'icon': Icons.check_circle_outline,
          'text': 'Success',
        };
      case WithdrawalStatus.failed:
        return {
          'color': AppColors.error,
          'icon': Icons.error_outline,
          'text': 'Failed',
        };
      case WithdrawalStatus.reversed:
        return {
          'color': Colors.grey,
          'icon': Icons.replay_outlined,
          'text': 'Reversed',
        };
    }
  }

  /// Gets the label for final timeline step
  String _getFinalStepLabel() {
    switch (withdrawalOrder.status) {
      case WithdrawalStatus.success:
        return 'Completed';
      case WithdrawalStatus.failed:
        return 'Failed';
      case WithdrawalStatus.reversed:
        return 'Reversed';
      default:
        return 'Completion';
    }
  }
}
