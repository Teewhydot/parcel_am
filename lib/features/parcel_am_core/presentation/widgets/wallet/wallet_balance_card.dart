import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../bloc/wallet/wallet_data.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.walletData,
  });

  final WalletData walletData;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      padding: AppSpacing.paddingXXL,
      child: Column(
        children: [
          AppText.bodyLarge(
            'Available Balance',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.headlineLarge(
            '${walletData.currency} ${walletData.availableBalance.toStringAsFixed(2)}',
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  AppText.bodySmall(
                    'Total Balance',
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppText.bodyLarge(
                    '${walletData.currency} ${walletData.balance.toStringAsFixed(2)}',
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              Column(
                children: [
                  AppText.bodySmall(
                    'Pending Balance',
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppText.bodyLarge(
                    '${walletData.currency} ${walletData.escrowBalance.toStringAsFixed(2)}',
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
