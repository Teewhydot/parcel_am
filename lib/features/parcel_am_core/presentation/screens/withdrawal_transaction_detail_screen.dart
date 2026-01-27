import 'package:flutter/material.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/theme/app_colors.dart';
import 'package:parcel_am/core/widgets/app_spacing.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/withdrawal_order_entity.dart';
import 'package:parcel_am/injection_container.dart';
import '../widgets/withdrawal/amount_card.dart';
import '../widgets/withdrawal/status_timeline.dart';
import '../widgets/withdrawal/bank_account_card.dart';
import '../widgets/withdrawal/transaction_details_card.dart';
import '../widgets/withdrawal/reason_card.dart';

class WithdrawalTransactionDetailScreen extends StatelessWidget {
  final WithdrawalOrderEntity withdrawalOrder;

  const WithdrawalTransactionDetailScreen({
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
            AmountCard(
              amount: withdrawalOrder.amount,
              status: withdrawalOrder.status,
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            StatusTimeline(withdrawalOrder: withdrawalOrder),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            BankAccountCard(bankAccount: withdrawalOrder.bankAccount),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            TransactionDetailsCard(withdrawalOrder: withdrawalOrder),
            if (withdrawalOrder.failureReason != null) ...[
              AppSpacing.verticalSpacing(SpacingSize.lg),
              FailureReasonCard(reason: withdrawalOrder.failureReason!),
            ],
            if (withdrawalOrder.reversalReason != null) ...[
              AppSpacing.verticalSpacing(SpacingSize.lg),
              ReversalReasonCard(reason: withdrawalOrder.reversalReason!),
            ],
            AppSpacing.verticalSpacing(SpacingSize.xxl),
            if (withdrawalOrder.status == WithdrawalStatus.failed)
              _RetryButton(withdrawalOrder: withdrawalOrder),
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.withdrawalOrder});

  final WithdrawalOrderEntity withdrawalOrder;

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      onPressed: () {
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
}
