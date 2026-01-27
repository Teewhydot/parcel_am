import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class AvailableBalanceCard extends StatelessWidget {
  const AvailableBalanceCard({
    super.key,
    required this.availableBalance,
  });

  final double availableBalance;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );

    return Center(
      child: AppCard.elevated(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              AppText.bodyMedium(
                'Available Balance',
                color: AppColors.onSurfaceVariant,
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              AppText.headlineMedium(
                currencyFormat.format(availableBalance),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
