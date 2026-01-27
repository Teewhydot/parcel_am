import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../bloc/wallet/wallet_cubit.dart';
import '../bloc/wallet/wallet_data.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_details_bottom_sheet.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/transaction_search_bar.dart';
import '../widgets/wallet/connectivity_banner.dart';
import '../widgets/wallet/wallet_balance_card.dart';
import '../widgets/wallet/wallet_action_buttons.dart';
import '../widgets/wallet/transaction_empty_state.dart';
import '../widgets/wallet/funding_modal.dart';

class WalletScreen extends StatefulWidget {
  final String userId;

  const WalletScreen({
    super.key,
    required this.userId,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletCubit>().start(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('My Wallet'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocManager<WalletCubit, BaseState<WalletData>>(
        bloc: context.read<WalletCubit>(),
        listener: (context, state) {
          if (state is AsyncErrorState<WalletData>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    AppText.bodyMedium(state.errorMessage, color: AppColors.white),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<WalletCubit>();
          final isOnline = bloc.isOnline;

          if (state.isLoading && !state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError && !state.hasData) {
            return _WalletErrorState(
              errorMessage: state.errorMessage ?? 'Failed to load wallet',
              onRetry: () => context.read<WalletCubit>().refresh(),
            );
          }

          final walletData = state.data ?? const WalletData();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WalletCubit>().refresh();
            },
            child: SingleChildScrollView(
              padding: AppSpacing.paddingLG,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConnectivityBanner(isOnline: isOnline),
                  WalletBalanceCard(walletData: walletData),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  WalletActionButtons(
                    isOnline: isOnline,
                    userId: widget.userId,
                    walletData: walletData,
                    onAddMoney: () => FundingModal.show(
                      context,
                      userId: widget.userId,
                    ),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xxl),
                  _TransactionHeader(
                    onRefresh: () => context.read<WalletCubit>().refresh(),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  TransactionSearchBar(
                    initialValue: walletData.wallet?.activeFilter.searchQuery,
                    onSearchChanged: (query) {
                      context.read<WalletCubit>().updateTransactionSearch(query);
                    },
                  ),
                  TransactionFilterBar(
                    currentFilter: walletData.wallet?.activeFilter ??
                        const TransactionFilter.empty(),
                    onFilterChanged: (filter) {
                      context.read<WalletCubit>().updateTransactionFilter(filter);
                    },
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  _TransactionList(walletData: walletData),
                  if (walletData.wallet?.hasMoreTransactions ?? false)
                    _LoadMoreButton(
                      isLoading: walletData.wallet?.isLoadingMore ?? false,
                      onPressed: () =>
                          context.read<WalletCubit>().loadMoreTransactions(),
                    ),
                  if (state is AsyncLoadingState)
                    if ((state as AsyncLoadingState).isRefreshing)
                      const LinearProgressIndicator(),
                ],
              ),
            ),
          );
        },
        child: Container(),
      ),
    );
  }
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyMedium(errorMessage),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppButton.primary(
            onPressed: onRetry,
            child: AppText.bodyMedium('Retry', color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _TransactionHeader extends StatelessWidget {
  const _TransactionHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          'Recent Transactions',
          variant: TextVariant.titleMedium,
          fontSize: AppFontSize.xl,
          fontWeight: FontWeight.bold,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh transactions',
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.walletData});

  final WalletData walletData;

  @override
  Widget build(BuildContext context) {
    if (walletData.wallet?.recentTransactions.isEmpty ?? true) {
      return TransactionEmptyState(
        hasActiveFilters: walletData.wallet?.activeFilter.hasActiveFilters ?? false,
      );
    }

    return AppCard.elevated(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: walletData.wallet!.recentTransactions.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 68,
        ),
        itemBuilder: (context, index) {
          final transaction = walletData.wallet!.recentTransactions[index];
          return TransactionListItem(
            transaction: transaction,
            onTap: () {
              TransactionDetailsBottomSheet.show(
                context,
                transaction,
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: AppButton.outline(
          onPressed: onPressed,
          loading: isLoading,
          child: AppText.bodyMedium('Load More', color: AppColors.primary),
        ),
      ),
    );
  }
}
