import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/user_bank_account_entity.dart';

class BankAccountOption extends StatelessWidget {
  const BankAccountOption({
    super.key,
    required this.account,
    required this.onTap,
  });

  final UserBankAccountEntity account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.account_balance, color: AppColors.primary),
      ),
      title: AppText.bodyMedium(
        account.accountName,
        fontWeight: FontWeight.w600,
      ),
      subtitle: AppText.bodySmall(
        '${account.bankName} - ${account.maskedAccountNumber}',
      ),
      onTap: onTap,
    );
  }
}
