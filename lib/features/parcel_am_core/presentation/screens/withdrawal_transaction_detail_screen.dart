import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/theme/app_colors.dart';
import 'package:parcel_am/core/theme/app_radius.dart';
import 'package:parcel_am/core/widgets/app_card.dart';
import 'package:parcel_am/core/widgets/app_spacing.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
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
        title: AppText.titleLarge('Withdrawal Details'),
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
    return AppCard.elevated(
      padding: AppSpacing.paddingXXL,
      child: Column(
        children: [
          AppText.bodyMedium(
            'Withdrawal Amount',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText(
            '₦${_formatAmount(withdrawalOrder.amount)}',
            variant: TextVariant.headlineLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          _buildStatusChip(context),
        ],
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
        borderRadius: AppRadius.xl,
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
          AppText.bodyMedium(
            statusInfo['text'],
            fontWeight: FontWeight.w600,
            color: statusInfo['color'],
          ),
        ],
      ),
    );
  }

  /// Builds the status timeline showing withdrawal progress
  Widget _buildStatusTimeline(BuildContext context) {
    return AppCard.elevated(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(
            'Transaction Timeline',
            fontWeight: FontWeight.w600,
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
                  color: isCompleted || isActive ? color : AppColors.transparent,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.white,
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
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    label,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isActive
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  AppText.bodySmall(
                    timestamp,
                    color: AppColors.onSurfaceVariant,
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
    return AppCard.elevated(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(
            'Bank Account',
            fontWeight: FontWeight.w600,
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
    );
  }

  /// Builds the transaction details card
  Widget _buildDetailsCard(BuildContext context) {
    return AppCard.elevated(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(
            'Transaction Details',
            fontWeight: FontWeight.w600,
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
    );
  }

  /// Builds the failure reason card
  Widget _buildFailureReasonCard(BuildContext context) {
    return AppCard.elevated(
      color: AppColors.error.withOpacity(0.05),
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
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              AppText(
                'Failure Reason',
                variant: TextVariant.titleSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            withdrawalOrder.failureReason!,
            color: AppColors.onSurface,
          ),
        ],
      ),
    );
  }

  /// Builds the reversal reason card
  Widget _buildReversalReasonCard(BuildContext context) {
    return AppCard.elevated(
      color: AppColors.pendingLight,
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.pendingDark,
                size: 20,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              AppText(
                'Reversal Reason',
                variant: TextVariant.titleSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.pendingDark,
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            withdrawalOrder.reversalReason!,
            color: AppColors.onSurface,
          ),
        ],
      ),
    );
  }

  /// Builds a detail row
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          label,
          color: AppColors.onSurfaceVariant,
        ),
        AppSpacing.horizontalSpacing(SpacingSize.lg),
        Flexible(
          child: AppText.bodyMedium(
            value,
            fontWeight: FontWeight.w500,
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
        AppText.bodyMedium(
          label,
          color: AppColors.onSurfaceVariant,
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

  /// Builds retry button for failed withdrawals
  Widget _buildRetryButton(BuildContext context) {
    return AppButton.primary(
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
      fullWidth: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.refresh, color: AppColors.white),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          AppText.bodyMedium('Retry Withdrawal', color: AppColors.white),
        ],
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
          'color': AppColors.pending,
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
          'color': AppColors.onSurfaceVariant,
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
