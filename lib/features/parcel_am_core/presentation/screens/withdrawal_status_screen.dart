import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../domain/entities/withdrawal_order_entity.dart';
import '../bloc/withdrawal/withdrawal_bloc.dart';
import '../bloc/withdrawal/withdrawal_data.dart';
import '../bloc/withdrawal/withdrawal_event.dart';

class WithdrawalStatusScreen extends StatefulWidget {
  final String withdrawalId;

  const WithdrawalStatusScreen({
    super.key,
    required this.withdrawalId,
  });

  @override
  State<WithdrawalStatusScreen> createState() => _WithdrawalStatusScreenState();
}

class _WithdrawalStatusScreenState extends State<WithdrawalStatusScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    // Start watching withdrawal status
    context.read<WithdrawalBloc>().add(
          WithdrawalStatusWatchRequested(withdrawalId: widget.withdrawalId),
        );
  }

  Color _getStatusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.processing:
        return Colors.blue;
      case WithdrawalStatus.success:
        return Colors.green;
      case WithdrawalStatus.failed:
        return Colors.red;
      case WithdrawalStatus.reversed:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return Icons.schedule;
      case WithdrawalStatus.processing:
        return Icons.sync;
      case WithdrawalStatus.success:
        return Icons.check_circle;
      case WithdrawalStatus.failed:
        return Icons.error;
      case WithdrawalStatus.reversed:
        return Icons.undo;
    }
  }

  String _getStatusMessage(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Your withdrawal request is being processed';
      case WithdrawalStatus.processing:
        return 'Transfer in progress. Please wait...';
      case WithdrawalStatus.success:
        return 'Funds have been transferred successfully';
      case WithdrawalStatus.failed:
        return 'Withdrawal failed. Funds have been returned to your wallet';
      case WithdrawalStatus.reversed:
        return 'Transfer was reversed. Funds have been returned to your wallet';
    }
  }

  String _getExpectedArrivalTime(WithdrawalStatus status, DateTime createdAt) {
    if (status == WithdrawalStatus.success) {
      return 'Completed';
    }
    if (status == WithdrawalStatus.failed || status == WithdrawalStatus.reversed) {
      return 'N/A';
    }

    final expectedTime = createdAt.add(const Duration(hours: 24));
    return _dateFormat.format(expectedTime);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Status'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<WithdrawalBloc, BaseState<WithdrawalData>>(
        builder: (context, state) {
          if (state.isLoading && !state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError && !state.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  Text(state.errorMessage ?? 'Failed to load withdrawal status'),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WithdrawalBloc>().add(
                            WithdrawalStatusWatchRequested(withdrawalId: widget.withdrawalId),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final withdrawalOrder = state.data?.withdrawalOrder;
          if (withdrawalOrder == null) {
            return const Center(
              child: Text('Withdrawal order not found'),
            );
          }

          final statusColor = _getStatusColor(withdrawalOrder.status);
          final statusIcon = _getStatusIcon(withdrawalOrder.status);

          return SingleChildScrollView(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  color: statusColor.withOpacity(0.1),
                  elevation: 0,
                  child: Padding(
                    padding: AppSpacing.paddingXL,
                    child: Column(
                      children: [
                        Icon(
                          statusIcon,
                          size: 64,
                          color: statusColor,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.md),
                        Text(
                          withdrawalOrder.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        Text(
                          _getStatusMessage(withdrawalOrder.status),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (withdrawalOrder.status == WithdrawalStatus.pending ||
                            withdrawalOrder.status == WithdrawalStatus.processing) ...[
                          AppSpacing.verticalSpacing(SpacingSize.md),
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.xl),

                // Amount Card
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(withdrawalOrder.amount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.lg),

                // Bank Account Details
                AppText.titleMedium('Bank Account Details', fontWeight: FontWeight.w600),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Bank Name', withdrawalOrder.bankAccount.bankName),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        _buildDetailRow('Account Name', withdrawalOrder.bankAccount.accountName),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        _buildDetailRow('Account Number', withdrawalOrder.bankAccount.accountNumber),
                      ],
                    ),
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.lg),

                // Transaction Details
                AppText.titleMedium('Transaction Details', fontWeight: FontWeight.w600),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRowWithCopy(
                          'Reference',
                          withdrawalOrder.id,
                          () => _copyToClipboard(withdrawalOrder.id, 'Reference'),
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        _buildDetailRow('Created', _dateFormat.format(withdrawalOrder.createdAt)),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        _buildDetailRow(
                          'Expected Arrival',
                          _getExpectedArrivalTime(withdrawalOrder.status, withdrawalOrder.createdAt),
                        ),
                        if (withdrawalOrder.processedAt != null) ...[
                          AppSpacing.verticalSpacing(SpacingSize.sm),
                          _buildDetailRow('Processed', _dateFormat.format(withdrawalOrder.processedAt!)),
                        ],
                      ],
                    ),
                  ),
                ),

                // Failure/Reversal Reason
                if (withdrawalOrder.failureReason != null) ...[
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Failure Reason',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.xs),
                              Text(
                                withdrawalOrder.failureReason!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (withdrawalOrder.reversalReason != null) ...[
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.purple.shade700),
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reversal Reason',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.xs),
                              Text(
                                withdrawalOrder.reversalReason!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                AppSpacing.verticalSpacing(SpacingSize.xl),

                // Action Buttons
                if (withdrawalOrder.status == WithdrawalStatus.success)
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('Back to Wallet'),
                    ),
                  ),

                if (withdrawalOrder.status == WithdrawalStatus.failed)
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      onPressed: () {
                        // Navigate back to wallet with retry option
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithCopy(String label, String value, VoidCallback onCopy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: onCopy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
