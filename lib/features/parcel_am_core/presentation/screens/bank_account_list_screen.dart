import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../domain/entities/user_bank_account_entity.dart';
import '../bloc/bank_account/bank_account_bloc.dart';
import '../bloc/bank_account/bank_account_data.dart';
import '../bloc/bank_account/bank_account_event.dart';
import '../widgets/add_bank_account_bottom_sheet.dart';
import '../widgets/bank_account/bank_account_empty_state.dart';
import '../widgets/bank_account/bank_account_error_state.dart';
import '../widgets/bank_account/bank_account_list_card.dart';
import '../widgets/bank_account/account_info_card.dart';

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
      context.read<BankAccountBloc>().add(
            BankAccountRefreshRequested(userId: widget.userId),
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
                content: AppText.bodyMedium(state.errorMessage, color: AppColors.white),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && !state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError && !state.hasData) {
            return BankAccountErrorState(
              errorMessage: state.errorMessage ?? 'Failed to load bank accounts',
              onRetry: () {
                context.read<BankAccountBloc>().add(
                      BankAccountLoadRequested(userId: widget.userId),
                    );
              },
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
                ? const BankAccountEmptyState()
                : _BankAccountList(
                    accounts: accounts,
                    data: data,
                    userId: widget.userId,
                  ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<BankAccountBloc, BaseState<BankAccountData>>(
        builder: (context, state) {
          final data = state.data ?? const BankAccountData();
          final canAddMore = !data.hasReachedMaxAccounts;

          return FloatingActionButton.extended(
            onPressed: canAddMore ? _showAddAccountModal : null,
            backgroundColor: canAddMore ? AppColors.primary : AppColors.textSecondary,
            icon: const Icon(Icons.add),
            label: AppText.bodyMedium('Add Account', color: AppColors.white),
          );
        },
      ),
    );
  }
}

class _BankAccountList extends StatelessWidget {
  const _BankAccountList({
    required this.accounts,
    required this.data,
    required this.userId,
  });

  final List<UserBankAccountEntity> accounts;
  final BankAccountData data;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.paddingLG,
      itemCount: accounts.length + 1,
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          return AccountInfoCard(
            hasReachedMaxAccounts: data.hasReachedMaxAccounts,
            remainingSlots: data.remainingAccountSlots,
          );
        }

        final account = accounts[index];
        return BankAccountListCard(
          account: account,
          isDefault: index == 0,
          userId: userId,
        );
      },
    );
  }
}
