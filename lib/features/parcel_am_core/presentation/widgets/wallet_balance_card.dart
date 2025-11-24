import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_data.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/auth/auth_bloc.dart';

class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({super.key});

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWallet();
    });
  }

  void _initializeWallet() {
    if (_initialized) return;

    final authState = context.read<AuthBloc>().state;
    final userId = authState.data?.user?.uid;

    if (userId != null && userId.isNotEmpty) {
      final walletState = context.read<WalletBloc>().state;
      // Only initialize if wallet is in initial state
      if (walletState.isInitial) {
        _initialized = true;
        context.read<WalletBloc>().add(WalletStarted(userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.data?.user?.uid ?? '';

    return BlocBuilder<WalletBloc, BaseState<WalletData>>(
      builder: (context, state) {
        if (state.isLoading && !state.hasData) {
          return _buildLoadingCard();
        } else if (state.hasData) {
          return _buildBalanceCard(context, state.data!, userId);
        } else if (state.isError) {
          return _buildErrorCard(context, state.errorMessage ?? 'Error loading wallet', userId);
        }
        return _buildLoadingCard();
      },
    );
  }

  Widget _buildLoadingCard() {
    return AppCard.elevated(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.filled(
                icon: Icons.account_balance_wallet,
                size: IconSize.small,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                color: AppColors.primary,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              AppText.titleMedium(
                'Wallet Balance',
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WalletData data, String userId) {
    return AppCard.elevated(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.filled(
                icon: Icons.account_balance_wallet,
                size: IconSize.small,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                color: AppColors.primary,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              AppText.titleMedium(
                'Wallet Balance',
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  label: 'Available',
                  amount: data.availableBalance,
                  color: AppColors.success,
                  icon: Icons.check_circle,
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              AppContainer(
                width: 1,
                height: 40,
                color: AppColors.surfaceVariant,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: _BalanceItem(
                  label: 'Pending',
                  amount: data.pendingBalance,
                  color: AppColors.accent,
                  icon: Icons.pending,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppContainer(
            variant: ContainerVariant.filled,
            color: AppColors.primary.withValues(alpha: 0.1),
            padding: AppSpacing.paddingMD,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(
                  'Total Balance',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                AppText.titleLarge(
                  '₦${_formatAmount(data.balance)}',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message, String userId) {
    return AppCard.elevated(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.filled(
                icon: Icons.account_balance_wallet,
                size: IconSize.small,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                color: AppColors.error,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              AppText.titleMedium(
                'Wallet Balance',
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          Center(
            child: Column(
              children: [
                AppText.bodyMedium(
                  message,
                  color: AppColors.error,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                TextButton(
                  onPressed: () {
                    if (userId.isNotEmpty) {
                      context.read<WalletBloc>().add(WalletStarted(userId));
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            AppSpacing.horizontalSpacing(SpacingSize.xs),
            AppText.labelMedium(
              label,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.xs),
        AppText.titleLarge(
          '₦${_formatAmount(amount)}',
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
