import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/user_bank_account_entity.dart';
import '../../bloc/withdrawal/withdrawal_bloc.dart';
import '../../bloc/withdrawal/withdrawal_event.dart';

class BankAccountSelectionSheet extends StatelessWidget {
  const BankAccountSelectionSheet({
    super.key,
    required this.accounts,
    required this.userId,
  });

  final List<UserBankAccountEntity> accounts;
  final String userId;

  static void show(
    BuildContext context, {
    required List<UserBankAccountEntity> accounts,
    required String userId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BankAccountSelectionSheet(
        accounts: accounts,
        userId: userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Select Bank Account', fontWeight: FontWeight.w600),
          AppSpacing.verticalSpacing(SpacingSize.md),
          ...accounts.map((account) => _AccountOption(account: account)),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppButton.text(
            onPressed: () {
              sl<NavigationService>().goBack();
              sl<NavigationService>().navigateTo(
                Routes.bankAccounts,
                arguments: {'userId': userId},
              );
            },
            child: AppText.bodyMedium('Manage Bank Accounts', color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({required this.account});

  final UserBankAccountEntity account;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.account_balance, color: AppColors.primary),
      ),
      title: AppText.bodyMedium(
        account.accountName,
        fontWeight: FontWeight.w600,
      ),
      subtitle: AppText.bodySmall(
        '${account.bankName} - ${account.maskedAccountNumber}',
      ),
      onTap: () {
        context.read<WithdrawalBloc>().add(
              WithdrawalBankAccountSelected(bankAccount: account),
            );
        Navigator.pop(context);
      },
    );
  }
}
