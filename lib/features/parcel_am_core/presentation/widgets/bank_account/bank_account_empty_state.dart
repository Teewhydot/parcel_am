import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class BankAccountEmptyState extends StatelessWidget {
  const BankAccountEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 80,
              color: AppColors.onSurfaceVariant,
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            AppText.titleLarge('No Bank Accounts', fontWeight: FontWeight.w600),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppText.bodyLarge(
              'Add a bank account to enable withdrawals',
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
          ],
        ),
      ),
    );
  }
}
