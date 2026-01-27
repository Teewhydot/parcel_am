import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/withdrawal_order_entity.dart';

class AmountCard extends StatelessWidget {
  const AmountCard({
    super.key,
    required this.amount,
    required this.status,
  });

  final double amount;
  final WithdrawalStatus status;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return AppCard.elevated(
      padding: AppSpacing.paddingXXL,
      child: Column(
        children: [
          AppText.bodyMedium(
            'Withdrawal Amount',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText(
            '₦${_formatAmount(amount)}',
            variant: TextVariant.headlineLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusInfo['color'].withValues(alpha: 0.1),
              borderRadius: AppRadius.xl,
              border: Border.all(color: statusInfo['color'] as Color),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusInfo['icon'] as IconData,
                  size: 16,
                  color: statusInfo['color'] as Color,
                ),
                AppSpacing.horizontalSpacing(SpacingSize.xs),
                AppText.bodyMedium(
                  statusInfo['text'] as String,
                  fontWeight: FontWeight.w600,
                  color: statusInfo['color'] as Color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  Map<String, dynamic> _getStatusInfo(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return {
          'color': AppColors.pending,
          'icon': Icons.pending_outlined,
          'text': 'Pending',
        };
      case WithdrawalStatus.processing:
        return {
          'color': AppColors.primary,
          'icon': Icons.hourglass_empty,
          'text': 'Processing',
        };
      case WithdrawalStatus.success:
        return {
          'color': AppColors.success,
          'icon': Icons.check_circle_outline,
          'text': 'Success',
        };
      case WithdrawalStatus.failed:
        return {
          'color': AppColors.error,
          'icon': Icons.error_outline,
          'text': 'Failed',
        };
      case WithdrawalStatus.reversed:
        return {
          'color': AppColors.onSurfaceVariant,
          'icon': Icons.replay_outlined,
          'text': 'Reversed',
        };
    }
  }
}
