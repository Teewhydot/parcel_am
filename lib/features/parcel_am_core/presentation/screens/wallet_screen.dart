import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/injection_container.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../payments/domain/use_cases/paystack_payment_usecase.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/wallet/wallet_data.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_details_bottom_sheet.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/transaction_search_bar.dart';

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
  double amount = 0.0;

  void _showFundingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FundingModalContent(
        userId: widget.userId,
        email: context.user.email,
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocManager<WalletBloc, BaseState<WalletData>>(
        bloc: context.read<WalletBloc>(),
        listener: (context, state) {
          // Show error snackbar when error occurs
          if (state is AsyncErrorState<WalletData>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<WalletBloc>();
          final isOnline = bloc.isOnline;

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
                  Text(state.errorMessage ?? 'Failed to load wallet'),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WalletBloc>().add(WalletRefreshRequested(widget.userId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final walletData = state.data ?? const WalletData();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(WalletRefreshRequested(widget.userId));
            },
            child: SingleChildScrollView(
              padding: AppSpacing.paddingLG,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connectivity warning banner
                  if (!isOnline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade700),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Expanded(
                            child: Text(
                              'No internet connection. Wallet operations are disabled.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: AppSpacing.paddingXXL,
                      child: Column(
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.sm),
                          Text(
                            '${walletData.currency} ${walletData.availableBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Total Balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${walletData.currency} ${walletData.balance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Pending Balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${walletData.currency} ${walletData.escrowBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: isOnline
                              ? 'Add funds to your wallet'
                              : 'Wallet operations require internet connection',
                          child: AppButton.primary(
                            onPressed: isOnline ? () => _showFundingModal(context) : null,
                            leadingIcon: const Icon(Icons.add),
                            requiresKyc: true,
                            child: const AppText("Add Money", color: AppColors.white),
                          ),
                        ),
                      ),
                      AppSpacing.horizontalSpacing(SpacingSize.md),
                      Expanded(
                        child: Tooltip(
                          message: isOnline
                              ? 'Withdraw funds from your wallet'
                              : 'Wallet operations require internet connection',
                          child: AppButton.secondary(
                              onPressed: isOnline
                                  ? () {
                                      sl<NavigationService>().navigateTo(
                                        Routes.withdrawal,
                                        arguments: {
                                          'userId': widget.userId,
                                          'availableBalance': walletData.availableBalance,
                                        },
                                      );
                                    }
                                  : null,
                              leadingIcon: const Icon(Icons.arrow_downward_outlined),
                              requiresKyc: true,
                              child: const AppText("Withdraw", color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          context.read<WalletBloc>().add(
                                const WalletTransactionsRefreshRequested(),
                              );
                        },
                        tooltip: 'Refresh transactions',
                      ),
                    ],
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),

                  // Search bar
                  TransactionSearchBar(
                    initialValue: walletData.wallet?.activeFilter.searchQuery,
                    onSearchChanged: (query) {
                      context.read<WalletBloc>().add(
                            WalletTransactionSearchChanged(query: query),
                          );
                    },
                  ),

                  // Filter bar
                  TransactionFilterBar(
                    currentFilter: walletData.wallet?.activeFilter ??
                        const TransactionFilter.empty(),
                    onFilterChanged: (filter) {
                      context.read<WalletBloc>().add(
                            WalletTransactionFilterChanged(filter: filter),
                          );
                    },
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.sm),

                  // Transaction list
                  if (walletData.wallet?.recentTransactions.isEmpty ?? true)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            AppSpacing.verticalSpacing(SpacingSize.md),
                            Text(
                              walletData.wallet?.activeFilter.hasActiveFilters ??
                                      false
                                  ? 'No transactions found'
                                  : 'No transactions yet',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: walletData.wallet!.recentTransactions.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 68,
                        ),
                        itemBuilder: (context, index) {
                          final transaction =
                              walletData.wallet!.recentTransactions[index];
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
                    ),

                  // Load more button
                  if (walletData.wallet?.hasMoreTransactions ?? false)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: walletData.wallet?.isLoadingMore ?? false
                            ? const CircularProgressIndicator()
                            : OutlinedButton(
                                onPressed: () {
                                  context.read<WalletBloc>().add(
                                        const WalletTransactionLoadMoreRequested(),
                                      );
                                },
                                child: const Text('Load More'),
                              ),
                      ),
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

class _FundingModalContent extends StatefulWidget {
  final String userId,transactionId,email;

  const _FundingModalContent({
    required this.userId,
    required this.transactionId,
    required this.email,
  });

  @override
  State<_FundingModalContent> createState() => _FundingModalContentState();
}

class _FundingModalContentState extends State<_FundingModalContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  final _paystackPaymentUseCase = PaystackPaymentUseCase();


  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (amount < 100) {
      return 'Minimum amount is 100';
    }

    if (amount > 1000000) {
      return 'Maximum amount is 1,000,000';
    }

    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text);

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize wallet funding via Paystack
      if (!mounted) return;
      final result = await _paystackPaymentUseCase.initializeWalletFunding(
        transactionId: widget.transactionId,
        amount: amount,
        email: widget.email,
      );

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
          });
          if (!mounted) return;
          context.showErrorMessage(failure.failureMessage);
        },
        (transaction) {
          setState(() {
            _isLoading = false;
          });
          if (!mounted) return;

          // Close the modal
          sl<NavigationService>().goBack();
          // Navigate to payment screen with authorization URL
          sl<NavigationService>().navigateTo(
            Routes.walletFundingPayment,
            arguments: {
              'authorizationUrl': transaction.authorizationUrl ?? '',
              'reference': transaction.reference,
              'transactionId': widget.transactionId,
              'userId': widget.userId,
              'amount': amount,
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize payment: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletData = context.read<WalletBloc>().state.data ?? const WalletData();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: AppSpacing.paddingXL,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant.withAlpha((0.3 * 255).toInt()),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Money to Wallet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    AppSpacing.verticalSpacing(SpacingSize.md),

                    // Current balance info
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.bodyMedium(
                            'Current Balance:',
                          ),
                          AppText.bodySmall(
                            '${walletData.currency} ${walletData.availableBalance.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.verticalSpacing(SpacingSize.lg),

                    // Amount input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter amount to add',
                        prefixText: '${walletData.currency} ',
                        prefixStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      validator: _validateAmount,
                      enabled: !_isLoading,
                      autofocus: true,
                    ),

                    AppSpacing.verticalSpacing(SpacingSize.sm),

                    // Helper text
                    AppText.bodySmall(
                      'Minimum: 100 • Maximum: 1,000,000',
                    ),

                    AppSpacing.verticalSpacing(SpacingSize.xl),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const AppText('Cancel', color: AppColors.onSurface),
                          ),
                        ),
                        AppSpacing.horizontalSpacing(SpacingSize.md),
                        Expanded(
                          child: AppButton.primary(
                            onPressed: _isLoading ? null : _handleSubmit,
                            leadingIcon: _isLoading
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.add, color: Colors.white),
                            requiresKyc: true,
                            child: AppText(
                              _isLoading ? 'Processing...' : 'Add Money',
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    AppSpacing.verticalSpacing(SpacingSize.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

  }
}
