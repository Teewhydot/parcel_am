import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../bloc/bank_account/bank_account_bloc.dart';
import '../bloc/bank_account/bank_account_data.dart';
import '../bloc/bank_account/bank_account_event.dart';
import '../bloc/withdrawal/withdrawal_bloc.dart';
import '../bloc/withdrawal/withdrawal_data.dart';
import '../bloc/withdrawal/withdrawal_event.dart';
import '../widgets/withdrawal/bank_account_selection_sheet.dart';
import '../widgets/withdrawal/withdrawal_confirmation_dialog.dart';
import '../widgets/withdrawal/no_bank_account_warning.dart';

class WithdrawalScreen extends StatefulWidget {
  final String userId;
  final double availableBalance;

  const WithdrawalScreen({
    super.key,
    required this.userId,
    required this.availableBalance,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    context.read<BankAccountBloc>().add(
          BankAccountLoadRequested(userId: widget.userId),
        );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initiateWithdrawal(double amount, bankAccount) {
    context.read<WithdrawalBloc>().add(
          WithdrawalInitiateRequested(
            userId: widget.userId,
            amount: amount,
            bankAccount: bankAccount,
            availableBalance: widget.availableBalance,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Withdraw Funds'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocManager<WithdrawalBloc, BaseState<WithdrawalData>>(
        bloc: context.read<WithdrawalBloc>(),
        showLoadingIndicator: false,
        listener: (context, state) {
          if (state is LoadedState<WithdrawalData> &&
              state.data?.withdrawalOrder != null) {
            sl<NavigationService>().navigateAndReplace(
              Routes.withdrawalStatus,
              arguments: {'withdrawalId': state.data?.withdrawalOrder?.id ?? ''},
            );
          }

          if (state is AsyncErrorState<WithdrawalData>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(state.errorMessage, color: AppColors.white),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, withdrawalState) {
          final withdrawalData = withdrawalState.data ?? const WithdrawalData();

          return BlocManager<BankAccountBloc, BaseState<BankAccountData>>(
            bloc: context.read<BankAccountBloc>(),
            showLoadingIndicator: false,
            builder: (context, bankAccountState) {
              final bankAccountData = bankAccountState.data ?? const BankAccountData();

              if (bankAccountState.isLoading && !bankAccountState.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: AppSpacing.paddingLG,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BalanceCard(
                        balance: widget.availableBalance,
                        currencyFormat: _currencyFormat,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xl),
                      _AmountInput(
                        controller: _amountController,
                        errorText: withdrawalData.amountError,
                        availableBalance: widget.availableBalance,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xl),
                      _BankAccountSection(
                        withdrawalData: withdrawalData,
                        bankAccountData: bankAccountData,
                        userId: widget.userId,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xxl),
                      _WithdrawButton(
                        canInitiate: withdrawalData.canInitiateWithdrawal,
                        isInitiating: withdrawalData.isInitiating,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final amount = double.parse(_amountController.text);
                            WithdrawalConfirmationDialog.show(
                              context,
                              amount: amount,
                              bankAccount: withdrawalData.selectedBankAccount!,
                              onConfirm: () => _initiateWithdrawal(
                                amount,
                                withdrawalData.selectedBankAccount!,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const SizedBox.shrink(),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.currencyFormat,
  });

  final double balance;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard.elevated(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              AppText.bodyMedium(
                'Available Balance',
                color: AppColors.onSurfaceVariant,
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              AppText.headlineMedium(
                currencyFormat.format(balance),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.errorText,
    required this.availableBalance,
  });

  final TextEditingController controller;
  final String? errorText;
  final double availableBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Withdrawal Amount', fontWeight: FontWeight.w600),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        AppInput(
          controller: controller,
          hintText: 'Enter amount',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          errorText: errorText,
          onChanged: (value) {
            context.read<WithdrawalBloc>().add(
                  WithdrawalAmountChanged(amount: value),
                );
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter amount';
            }
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Invalid amount';
            }
            if (amount > availableBalance) {
              return 'Insufficient balance';
            }
            return null;
          },
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        AppText.bodySmall(
          'Min: ₦100 • Max: ₦500,000',
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _BankAccountSection extends StatelessWidget {
  const _BankAccountSection({
    required this.withdrawalData,
    required this.bankAccountData,
    required this.userId,
  });

  final WithdrawalData withdrawalData;
  final BankAccountData bankAccountData;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Bank Account', fontWeight: FontWeight.w600),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        if (withdrawalData.selectedBankAccount != null)
          AppCard.elevated(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.account_balance, color: AppColors.primary),
              ),
              title: AppText.bodyMedium(
                withdrawalData.selectedBankAccount!.accountName,
                fontWeight: FontWeight.w600,
              ),
              subtitle: AppText.bodySmall(
                '${withdrawalData.selectedBankAccount!.bankName} - ${withdrawalData.selectedBankAccount!.maskedAccountNumber}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: bankAccountData.userBankAccounts.isNotEmpty
                    ? () => BankAccountSelectionSheet.show(
                          context,
                          accounts: bankAccountData.userBankAccounts,
                          userId: userId,
                        )
                    : null,
              ),
            ),
          )
        else
          AppButton.outline(
            onPressed: bankAccountData.userBankAccounts.isNotEmpty
                ? () => BankAccountSelectionSheet.show(
                      context,
                      accounts: bankAccountData.userBankAccounts,
                      userId: userId,
                    )
                : null,
            fullWidth: true,
            leadingIcon: const Icon(Icons.account_balance),
            child: AppText.bodyMedium('Select Bank Account', color: AppColors.primary),
          ),
        if (bankAccountData.userBankAccounts.isEmpty) ...[
          AppSpacing.verticalSpacing(SpacingSize.sm),
          NoBankAccountWarning(userId: userId),
        ],
      ],
    );
  }
}

class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({
    required this.canInitiate,
    required this.isInitiating,
    required this.onPressed,
  });

  final bool canInitiate;
  final bool isInitiating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton.primary(
        onPressed: canInitiate && !isInitiating ? onPressed : null,
        loading: isInitiating,
        child: const AppText('Withdraw', color: AppColors.white),
      ),
    );
  }
}
