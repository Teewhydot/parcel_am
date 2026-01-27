import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/user_bank_account_entity.dart';

class WithdrawalConfirmationDialog extends StatelessWidget {
  const WithdrawalConfirmationDialog({
    super.key,
    required this.amount,
    required this.bankAccount,
    required this.onConfirm,
  });

  final double amount;
  final UserBankAccountEntity bankAccount;
  final VoidCallback onConfirm;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  static Future<void> show(
    BuildContext context, {
    required double amount,
    required UserBankAccountEntity bankAccount,
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => WithdrawalConfirmationDialog(
        amount: amount,
        bankAccount: bankAccount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText.titleMedium('Confirm Withdrawal', fontWeight: FontWeight.w600),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(
            'Amount: ${_currencyFormat.format(amount)}',
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium('Bank: ${bankAccount.bankName}'),
          AppText.bodyMedium('Account: ${bankAccount.accountName}'),
          AppText.bodyMedium('Number: ${bankAccount.maskedAccountNumber}'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: AppRadius.sm,
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                AppSpacing.horizontalSpacing(SpacingSize.sm),
                Expanded(
                  child: AppText.bodySmall(
                    'Funds will be transferred to your account within 24 hours',
                    color: AppColors.warningDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(context),
          child: AppText.bodyMedium('Cancel', color: AppColors.primary),
        ),
        AppButton.primary(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: AppText.bodyMedium('Confirm', color: AppColors.white),
        ),
      ],
    );
  }
}
