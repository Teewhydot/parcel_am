import 'package:flutter/material.dart';
import 'package:parcel_am/core/services/auth/kyc_guard.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/helpers/user_extensions.dart';
import 'action_card.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: KycGestureDetector(
            onTap: () => sl<NavigationService>().navigateTo(Routes.createParcel),
            child: const ActionCard(
              icon: Icons.add,
              title: 'Send Package',
              subtitle: 'Create a new delivery request',
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: KycGestureDetector(
            onTap: () {
              sl<NavigationService>().navigateTo(
                Routes.wallet,
                arguments: context.currentUserId ?? '',
              );
            },
            child: const ActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: 'View your wallet',
              color: AppColors.info,
            ),
          ),
        ),
      ],
    );
  }
}
