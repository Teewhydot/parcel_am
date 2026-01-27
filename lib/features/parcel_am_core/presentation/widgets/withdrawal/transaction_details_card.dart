import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/withdrawal_order_entity.dart';
import 'detail_row.dart';

class TransactionDetailsCard extends StatelessWidget {
  const TransactionDetailsCard({
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
            'Transaction Details',
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          CopyableDetailRow(
            label: 'Reference ID',
            value: withdrawalOrder.id,
          ),
          const Divider(height: 20),
          DetailRow(
            label: 'Created',
            value: _formatDateTime(withdrawalOrder.createdAt),
          ),
          const Divider(height: 20),
          DetailRow(
            label: 'Last Updated',
            value: _formatDateTime(withdrawalOrder.updatedAt),
          ),
          if (withdrawalOrder.processedAt != null) ...[
            const Divider(height: 20),
            DetailRow(
              label: 'Processed',
              value: _formatDateTime(withdrawalOrder.processedAt!),
            ),
          ],
          if (withdrawalOrder.transferCode != null) ...[
            const Divider(height: 20),
            CopyableDetailRow(
              label: 'Transfer Code',
              value: withdrawalOrder.transferCode!,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • hh:mm a').format(dateTime);
  }
}
