import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../domain/entities/user_bank_account_entity.dart';
import '../bloc/bank_account/bank_account_bloc.dart';
import '../bloc/bank_account/bank_account_data.dart';
import '../bloc/bank_account/bank_account_event.dart';
import '../bloc/withdrawal/withdrawal_bloc.dart';
import '../bloc/withdrawal/withdrawal_data.dart';
import '../bloc/withdrawal/withdrawal_event.dart';

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
    // Load user bank accounts
    context.read<BankAccountBloc>().add(
          BankAccountLoadRequested(userId: widget.userId),
        );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showBankAccountSelection(List<UserBankAccountEntity> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
            ...accounts.map((account) => _buildAccountOption(account)),
            AppSpacing.verticalSpacing(SpacingSize.md),
            TextButton(
              onPressed: () {
                sl<NavigationService>().goBack();
                sl<NavigationService>().navigateTo(
                  Routes.bankAccounts,
                  arguments: {'userId': widget.userId},
                );
              },
              child: AppText.bodyMedium('Manage Bank Accounts', color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOption(UserBankAccountEntity account) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
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

  void _showConfirmationDialog(
    double amount,
    UserBankAccountEntity bankAccount,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodySmall(
                      'Funds will be transferred to your account within 24 hours',
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText.bodyMedium('Cancel', color: AppColors.primary),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateWithdrawal(amount, bankAccount);
            },
            child: AppText.bodyMedium('Confirm', color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _initiateWithdrawal(double amount, UserBankAccountEntity bankAccount) {
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<WithdrawalBloc, BaseState<WithdrawalData>>(
            listener: (context, state) {
              // Navigate to status screen when withdrawal initiated
              if (state is LoadedState<WithdrawalData> &&
                  state.data?.withdrawalOrder != null) {
                sl<NavigationService>().navigateAndReplace(
                  Routes.withdrawalStatus,
                  arguments: {'withdrawalId': state.data?.withdrawalOrder?.id ?? ''},
                );
              }

              // Show errors
              if (state is AsyncErrorState<WithdrawalData>) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText.bodyMedium(state.errorMessage, color: Colors.white),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<WithdrawalBloc, BaseState<WithdrawalData>>(
          builder: (context, withdrawalState) {
            final withdrawalData = withdrawalState.data ?? const WithdrawalData();

            return BlocBuilder<BankAccountBloc, BaseState<BankAccountData>>(
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
                        // Available Balance Card
                        Center(
                          child: Card(
                            color: AppColors.primary.withOpacity(0.1),
                            child: Padding(
                              padding: AppSpacing.paddingLG,
                              child: Column(
                                children: [
                                  AppText.bodyMedium(
                                    'Available Balance',
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  AppSpacing.verticalSpacing(SpacingSize.sm),
                                  AppText(
                                    _currencyFormat.format(widget.availableBalance),
                                    variant: TextVariant.headlineMedium,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        AppSpacing.verticalSpacing(SpacingSize.xl),

                        // Amount Input
                        AppText.titleMedium('Withdrawal Amount', fontWeight: FontWeight.w600),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter amount',
                            prefixText: '₦ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            errorText: withdrawalData.amountError,
                          ),
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
                            if (amount > widget.availableBalance) {
                              return 'Insufficient balance';
                            }
                            return null;
                          },
                        ),

                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        AppText.bodySmall(
                          'Min: ₦100 • Max: ₦500,000',
                          color: Colors.grey.shade600,
                        ),

                        AppSpacing.verticalSpacing(SpacingSize.xl),

                        // Bank Account Selection
                        AppText.titleMedium('Bank Account', fontWeight: FontWeight.w600),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        if (withdrawalData.selectedBankAccount != null)
                          Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
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
                                    ? () => _showBankAccountSelection(
                                          bankAccountData.userBankAccounts,
                                        )
                                    : null,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: bankAccountData.userBankAccounts.isNotEmpty
                                  ? () => _showBankAccountSelection(
                                        bankAccountData.userBankAccounts,
                                      )
                                  : null,
                              icon: const Icon(Icons.account_balance),
                              label: AppText.bodyMedium('Select Bank Account', color: AppColors.primary),
                            ),
                          ),

                        if (bankAccountData.userBankAccounts.isEmpty) ...[
                          AppSpacing.verticalSpacing(SpacingSize.sm),
                          Container(
                            padding: AppSpacing.paddingMD,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700),
                                AppSpacing.horizontalSpacing(SpacingSize.sm),
                                Expanded(
                                  child: AppText.bodyMedium(
                                    'Please add a bank account first',
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.md),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton.primary(
                              onPressed: () {
                                sl<NavigationService>().navigateTo(
                                  Routes.bankAccounts,
                                  arguments: {'userId': widget.userId},
                                );
                              },
                              leadingIcon: const Icon(Icons.add, color: Colors.white),
                              child: const AppText('Add Bank Account', color: AppColors.white),
                            ),
                          ),
                        ],

                        AppSpacing.verticalSpacing(SpacingSize.xxl),

                        // Withdraw Button
                        SizedBox(
                          width: double.infinity,
                          child: AppButton.primary(
                            onPressed: withdrawalData.canInitiateWithdrawal &&
                                    !withdrawalData.isInitiating
                                ? () {
                                    if (_formKey.currentState!.validate()) {
                                      final amount = double.parse(_amountController.text);
                                      _showConfirmationDialog(
                                        amount,
                                        withdrawalData.selectedBankAccount!,
                                      );
                                    }
                                  }
                                : null,
                            loading: withdrawalData.isInitiating,
                            child: const AppText('Withdraw', color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
