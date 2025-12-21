import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/user_bank_account_entity.dart';
import '../bloc/bank_account/bank_account_bloc.dart';
import '../bloc/bank_account/bank_account_data.dart';
import '../bloc/bank_account/bank_account_event.dart';
import '../widgets/add_bank_account_bottom_sheet.dart';

class BankAccountListScreen extends StatefulWidget {
  final String userId;

  const BankAccountListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<BankAccountListScreen> createState() => _BankAccountListScreenState();
}

class _BankAccountListScreenState extends State<BankAccountListScreen> {
  @override
  void initState() {
    super.initState();
    // Load user bank accounts when screen opens
    context.read<BankAccountBloc>().add(
          BankAccountLoadRequested(userId: widget.userId),
        );
  }

  Future<void> _showAddAccountModal() async {
    final result = await AddBankAccountBottomSheet.show(
      context,
      userId: widget.userId,
    );

    if (result == true && mounted) {
      // Refresh the list after adding
      context.read<BankAccountBloc>().add(
            BankAccountRefreshRequested(userId: widget.userId),
          );
    }
  }

  Future<void> _confirmDeleteAccount(UserBankAccountEntity account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.titleMedium('Delete Bank Account', fontWeight: FontWeight.w600),
        content: AppText.bodyMedium(
          'Are you sure you want to delete ${account.bankName} - ${account.maskedAccountNumber}?',
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.bodyMedium('Cancel', color: AppColors.primary),
          ),
          AppButton.text(
            onPressed: () => Navigator.pop(context, true),
            child: AppText.bodyMedium('Delete', color: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<BankAccountBloc>().add(
            BankAccountDeleteRequested(
              userId: widget.userId,
              accountId: account.id,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Saved Bank Accounts'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BankAccountBloc>().add(
                    BankAccountRefreshRequested(userId: widget.userId),
                  );
            },
          ),
        ],
      ),
      body: BlocConsumer<BankAccountBloc, BaseState<BankAccountData>>(
        listener: (context, state) {
          if (state is AsyncErrorState<BankAccountData>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(state.errorMessage, color: Colors.white),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && !state.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.isError && !state.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  AppText.bodyMedium(state.errorMessage ?? 'Failed to load bank accounts'),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  AppButton.primary(
                    onPressed: () {
                      context.read<BankAccountBloc>().add(
                            BankAccountLoadRequested(userId: widget.userId),
                          );
                    },
                    child: AppText.bodyMedium('Retry', color: Colors.white),
                  ),
                ],
              ),
            );
          }

          final data = state.data ?? const BankAccountData();
          final accounts = data.userBankAccounts;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BankAccountBloc>().add(
                    BankAccountRefreshRequested(userId: widget.userId),
                  );
            },
            child: accounts.isEmpty
                ? _buildEmptyState(data)
                : _buildAccountList(accounts, data),
          );
        },
      ),
      floatingActionButton: BlocBuilder<BankAccountBloc, BaseState<BankAccountData>>(
        builder: (context, state) {
          final data = state.data ?? const BankAccountData();
          final canAddMore = !data.hasReachedMaxAccounts;

          return FloatingActionButton.extended(
            onPressed: canAddMore ? _showAddAccountModal : null,
            backgroundColor: canAddMore ? AppColors.primary : Colors.grey,
            icon: const Icon(Icons.add),
            label: AppText.bodyMedium('Add Account', color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BankAccountData data) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 80,
              color: Colors.grey.shade400,
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            AppText.titleLarge('No Bank Accounts', fontWeight: FontWeight.w600),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppText.bodyLarge(
              'Add a bank account to enable withdrawals',
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
          
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList(
    List<UserBankAccountEntity> accounts,
    BankAccountData data,
  ) {
    return ListView.builder(
      padding: AppSpacing.paddingLG,
      itemCount: accounts.length + 1, // +1 for info card
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          // Info card at the end
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            child: Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodyMedium(
                      data.hasReachedMaxAccounts
                          ? 'Maximum of 5 bank accounts reached'
                          : 'You can add ${data.remainingAccountSlots} more account(s)',
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final account = accounts[index];
        return _buildAccountCard(account, index == 0);
      },
    );
  }

  Widget _buildAccountCard(UserBankAccountEntity account, bool isDefault) {
    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Dismissible(
        key: Key(account.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 32,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: AppText.titleMedium('Delete Bank Account', fontWeight: FontWeight.w600),
              content: AppText.bodyMedium(
                'Are you sure you want to delete ${account.bankName} - ${account.maskedAccountNumber}?',
              ),
              actions: [
                AppButton.text(
                  onPressed: () => Navigator.pop(context, false),
                  child: AppText.bodyMedium('Cancel', color: AppColors.primary),
                ),
                AppButton.text(
                  onPressed: () => Navigator.pop(context, true),
                  child: AppText.bodyMedium('Delete', color: Colors.red),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          context.read<BankAccountBloc>().add(
                BankAccountDeleteRequested(
                  userId: widget.userId,
                  accountId: account.id,
                ),
              );
        },
        child: ListTile(
          contentPadding: AppSpacing.paddingMD,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(
              Icons.account_balance,
              color: AppColors.primary,
            ),
          ),
          title: AppText.bodyLarge(
            account.accountName,
            fontWeight: FontWeight.w600,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText.bodyMedium(
                account.bankName,
                color: Colors.grey.shade700,
              ),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText.bodyMedium(
                account.maskedAccountNumber,
                color: Colors.grey.shade600,
              ),
              if (isDefault) ...[
                AppSpacing.verticalSpacing(SpacingSize.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AppText(
                    'DEFAULT',
                    variant: TextVariant.bodySmall,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeleteAccount(account),
          ),
        ),
      ),
    );
  }
}
