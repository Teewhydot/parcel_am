import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/wallet/wallet_data.dart';

class WalletScreen extends StatelessWidget {
  final String userId;

  const WalletScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletBloc()..add(WalletStarted(userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Wallet'),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: BlocConsumer<WalletBloc, BaseState<WalletData>>(
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
                        context.read<WalletBloc>().add(WalletRefreshRequested(userId));
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
                context.read<WalletBloc>().add(WalletRefreshRequested(userId));
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
                            child: ElevatedButton.icon(
                              onPressed: isOnline ? () {} : null,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Funds'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOnline ? AppColors.primary : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: AppSpacing.paddingLG,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.horizontalSpacing(SpacingSize.md),
                        Expanded(
                          child: Tooltip(
                            message: isOnline
                                ? 'Withdraw funds from your wallet'
                                : 'Wallet operations require internet connection',
                            child: ElevatedButton.icon(
                              onPressed: isOnline ? () {} : null,
                              icon: const Icon(Icons.arrow_upward),
                              label: const Text('Withdraw'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOnline ? AppColors.surfaceVariant : Colors.grey,
                                foregroundColor: isOnline ? AppColors.onSurface : Colors.grey.shade600,
                                padding: AppSpacing.paddingLG,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xxl),
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    if (walletData.wallet?.recentTransactions.isEmpty ?? true)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                            ),
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
        ),
      ),
    );
  }
}
