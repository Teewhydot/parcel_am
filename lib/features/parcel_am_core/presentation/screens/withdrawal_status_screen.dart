import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/withdrawal_order_entity.dart';
import '../bloc/withdrawal/withdrawal_bloc.dart';
import '../bloc/withdrawal/withdrawal_data.dart';
import '../bloc/withdrawal/withdrawal_event.dart';
import '../widgets/withdrawal/detail_row.dart';

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
    return switch (status) {
      WithdrawalStatus.pending => AppColors.pending,
      WithdrawalStatus.processing => AppColors.processing,
      WithdrawalStatus.success => AppColors.success,
      WithdrawalStatus.failed => AppColors.error,
      WithdrawalStatus.reversed => AppColors.reversed,
    };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Withdrawal Status'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocManager<WithdrawalBloc, BaseState<WithdrawalData>>(
        bloc: context.read<WithdrawalBloc>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: false,
        child: const SizedBox.shrink(),
        builder: (context, state) {
          if (state.isLoading && !state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError && !state.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  AppText.bodyMedium(state.errorMessage ?? 'Failed to load withdrawal status'),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  AppButton.primary(
                    onPressed: () {
                      context.read<WithdrawalBloc>().add(
                            WithdrawalStatusWatchRequested(withdrawalId: widget.withdrawalId),
                          );
                    },
                    child: AppText.bodyMedium('Retry', color: AppColors.white),
                  ),
                ],
              ),
            );
          }

          final withdrawalOrder = state.data?.withdrawalOrder;
          if (withdrawalOrder == null) {
            return Center(
              child: AppText.bodyMedium('Withdrawal order not found'),
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
                Padding(
                  padding: AppSpacing.paddingXL,
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          statusIcon,
                          size: 64,
                          color: statusColor,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.md),
                        AppText(
                          withdrawalOrder.status.name.toUpperCase(),
                          variant: TextVariant.titleLarge,
                          fontSize: AppFontSize.xxl,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        AppText.bodyMedium(
                          _getStatusMessage(withdrawalOrder.status),
                          textAlign: TextAlign.center,
                          color: AppColors.onSurfaceVariant,
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
                AppCard.elevated(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.bodyLarge(
                        'Amount',
                        color: AppColors.onSurfaceVariant,
                      ),
                      AppText.headlineSmall(
                        _currencyFormat.format(withdrawalOrder.amount),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.lg),

                // Bank Account Details
                AppText.titleMedium('Bank Account Details', fontWeight: FontWeight.w600),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                AppCard.elevated(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailRow(label: 'Bank Name', value: withdrawalOrder.bankAccount.bankName),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      DetailRow(label: 'Account Name', value: withdrawalOrder.bankAccount.accountName),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      DetailRow(label: 'Account Number', value: withdrawalOrder.bankAccount.accountNumber),
                    ],
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.lg),

                // Transaction Details
                AppText.titleMedium('Transaction Details', fontWeight: FontWeight.w600),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                AppCard.elevated(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailRowWithCopy(
                        label: 'Reference',
                        value: withdrawalOrder.id,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      DetailRow(label: 'Created', value: _dateFormat.format(withdrawalOrder.createdAt)),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      DetailRow(
                        label: 'Expected Arrival',
                        value: _getExpectedArrivalTime(withdrawalOrder.status, withdrawalOrder.createdAt),
                      ),
                      if (withdrawalOrder.processedAt != null) ...[
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        DetailRow(label: 'Processed', value: _dateFormat.format(withdrawalOrder.processedAt!)),
                      ],
                    ],
                  ),
                ),

                // Failure/Reversal Reason
                if (withdrawalOrder.failureReason != null) ...[
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppRadius.sm,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodyMedium(
                                'Failure Reason',
                                fontWeight: FontWeight.bold,
                                color: AppColors.errorDark,
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.xs),
                              AppText.bodyMedium(
                                withdrawalOrder.failureReason!,
                                color: AppColors.errorDark,
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
                      color: AppColors.reversedLight,
                      borderRadius: AppRadius.sm,
                      border: Border.all(color: AppColors.reversed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.reversed),
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodyMedium(
                                'Reversal Reason',
                                fontWeight: FontWeight.bold,
                                color: AppColors.reversedDark,
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.xs),
                              AppText.bodyMedium(
                                withdrawalOrder.reversalReason!,
                                color: AppColors.reversedDark,
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
                  AppButton.primary(
                    onPressed: () {
                      sl<NavigationService>().navigateAndReplaceAll(Routes.home);
                    },
                    fullWidth: true,
                    child: const AppText('Back to Wallet', color: AppColors.white),
                  ),

                if (withdrawalOrder.status == WithdrawalStatus.failed)
                  AppButton.primary(
                    onPressed: () {
                      // Navigate back to wallet with retry option
                      sl<NavigationService>().navigateAndReplaceAll(Routes.home);
                    },
                    fullWidth: true,
                    child: const AppText('Try Again', color: AppColors.white),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
