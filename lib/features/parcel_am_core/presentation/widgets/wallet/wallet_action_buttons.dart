import 'package:flutter/material.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';
import '../../bloc/wallet/wallet_data.dart';

class WalletActionButtons extends StatelessWidget {
  const WalletActionButtons({
    super.key,
    required this.isOnline,
    required this.userId,
    required this.walletData,
    required this.onAddMoney,
  });

  final bool isOnline;
  final String userId;
  final WalletData walletData;
  final VoidCallback onAddMoney;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: isOnline
                ? 'Add funds to your wallet'
                : 'Wallet operations require internet connection',
            child: AppButton.primary(
              onPressed: isOnline ? onAddMoney : null,
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
                          'userId': userId,
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
    );
  }
}
