import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';

class TransactionDetailsCard extends StatelessWidget {
  const TransactionDetailsCard({
    super.key,
    required this.currency,
    required this.amount,
    required this.availableBalance,
    required this.reference,
    required this.paymentStatus,
    required this.isSuccess,
    required this.isPending,
    required this.isLoading,
  });

  final String currency;
  final double amount;
  final double availableBalance;
  final String reference;
  final String paymentStatus;
  final bool isSuccess;
  final bool isPending;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingXL,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Amount
          const AppText(
            'Amount',
            fontSize: AppFontSize.bodyMedium,
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText(
            '$currency ${amount.toStringAsFixed(2)}',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),

          AppSpacing.verticalSpacing(SpacingSize.lg),

          // Divider
          const Divider(
            color: AppColors.outline,
          ),

          AppSpacing.verticalSpacing(SpacingSize.lg),

          // New Balance (only show for successful payments)
          if (isSuccess) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText(
                  'New Wallet Balance:',
                  fontSize: AppFontSize.bodyMedium,
                  color: AppColors.onSurfaceVariant,
                ),
                AppText(
                  '$currency ${availableBalance.toStringAsFixed(2)}',
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
          ],

          // Status badge
          if (!isLoading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText(
                  'Status:',
                  fontSize: AppFontSize.bodySmall,
                  color: AppColors.onSurfaceVariant,
                ),
                Container(
                  padding: AppSpacing.paddingSM,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? AppColors.success.withValues(alpha: 0.1)
                        : isPending
                            ? AppColors.pending.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppRadius.md,
                  ),
                  child: AppText(
                    paymentStatus.toUpperCase(),
                    fontSize: AppFontSize.xs,
                    fontWeight: FontWeight.bold,
                    color: isSuccess
                        ? AppColors.successDark
                        : isPending
                            ? AppColors.pendingDark
                            : AppColors.errorDark,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
          ],

          // Transaction Reference
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Reference:',
                fontSize: AppFontSize.bodySmall,
                color: AppColors.onSurfaceVariant,
              ),
              AppText(
                reference,
                fontSize: AppFontSize.bodySmall,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
