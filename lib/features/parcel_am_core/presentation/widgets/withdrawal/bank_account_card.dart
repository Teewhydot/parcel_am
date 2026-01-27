import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/withdrawal_order_entity.dart';
import 'detail_row.dart';

class BankAccountCard extends StatelessWidget {
  const BankAccountCard({
    super.key,
    required this.bankAccount,
    this.maskAccountNumber = true,
  });

  final BankAccountInfo bankAccount;
  final bool maskAccountNumber;

  @override
  Widget build(BuildContext context) {
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
          DetailRow(
            label: 'Account Name',
            value: bankAccount.accountName,
          ),
          const Divider(height: 20),
          DetailRow(
            label: 'Account Number',
            value: maskAccountNumber
                ? _maskAccountNumber(bankAccount.accountNumber)
                : bankAccount.accountNumber,
          ),
          const Divider(height: 20),
          DetailRow(
            label: 'Bank',
            value: bankAccount.bankName,
          ),
        ],
      ),
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return '******${accountNumber.substring(accountNumber.length - 4)}';
  }
}
