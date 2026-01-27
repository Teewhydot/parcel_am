import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/withdrawal_order_entity.dart';
import 'timeline_item.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.withdrawalOrder,
  });

  final WithdrawalOrderEntity withdrawalOrder;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(
            'Transaction Timeline',
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          TimelineItem(
            label: 'Initiated',
            timestamp: _formatDateTime(withdrawalOrder.createdAt),
            isCompleted: true,
          ),
          TimelineItem(
            label: 'Processing',
            timestamp: withdrawalOrder.status != WithdrawalStatus.pending
                ? _formatDateTime(withdrawalOrder.updatedAt)
                : 'Waiting...',
            isCompleted: withdrawalOrder.status != WithdrawalStatus.pending,
            isActive: withdrawalOrder.status == WithdrawalStatus.processing,
          ),
          TimelineItem(
            label: _getFinalStepLabel(),
            timestamp: withdrawalOrder.processedAt != null
                ? _formatDateTime(withdrawalOrder.processedAt!)
                : 'Pending...',
            isCompleted: withdrawalOrder.status == WithdrawalStatus.success ||
                withdrawalOrder.status == WithdrawalStatus.failed ||
                withdrawalOrder.status == WithdrawalStatus.reversed,
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • hh:mm a').format(dateTime);
  }

  String _getFinalStepLabel() {
    switch (withdrawalOrder.status) {
      case WithdrawalStatus.success:
        return 'Completed';
      case WithdrawalStatus.failed:
        return 'Failed';
      case WithdrawalStatus.reversed:
        return 'Reversed';
      default:
        return 'Completion';
    }
  }
}
