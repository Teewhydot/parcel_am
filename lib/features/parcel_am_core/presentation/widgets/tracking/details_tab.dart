import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/package_entity.dart';
import 'detail_row.dart';
import 'delivery_confirmation_card.dart';
import 'dispute_escrow_card.dart';
import 'route_information_card.dart';

class DetailsTab extends StatelessWidget {
  const DetailsTab({
    super.key,
    required this.package,
    required this.confirmationCodeController,
    required this.disputeReasonController,
  });

  final PackageEntity package;
  final TextEditingController confirmationCodeController;
  final TextEditingController disputeReasonController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('Package Details'),
                AppSpacing.verticalSpacing(SpacingSize.md),
                DetailRow(label: 'Type', value: package.packageType),
                DetailRow(label: 'Weight', value: '${package.weight} kg'),
                DetailRow(label: 'Urgency', value: package.urgency),
                DetailRow(label: 'Created', value: _formatDate(package.createdAt)),
                DetailRow(label: 'Est. Arrival', value: _formatDate(package.estimatedArrival)),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          if (package.paymentInfo != null) ...[
            AppCard.elevated(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.titleMedium('Payment & Escrow'),
                      Icon(Icons.lock, color: _getEscrowStatusColor(package.paymentInfo!.escrowStatus), size: 20),
                    ],
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  DetailRow(label: 'Amount', value: '₦${package.paymentInfo!.amount.toStringAsFixed(2)}'),
                  DetailRow(label: 'Service Fee', value: '₦${package.paymentInfo!.serviceFee.toStringAsFixed(2)}'),
                  DetailRow(label: 'Total', value: '₦${package.paymentInfo!.totalAmount.toStringAsFixed(2)}'),
                  DetailRow(label: 'Escrow Status', value: package.paymentInfo!.escrowStatus.toUpperCase()),
                  if (package.paymentInfo!.escrowHeldAt != null)
                    DetailRow(label: 'Held Since', value: _formatDate(package.paymentInfo!.escrowHeldAt!)),
                ],
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
          ],
          if (package.status == 'delivered' && package.paymentInfo?.escrowStatus == 'held') ...[
            DeliveryConfirmationCard(
              package: package,
              confirmationCodeController: confirmationCodeController,
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
          ],
          if (package.paymentInfo?.escrowStatus == 'held') ...[
            DisputeEscrowCard(
              package: package,
              disputeReasonController: disputeReasonController,
            ),
          ],
          AppSpacing.verticalSpacing(SpacingSize.lg),
          RouteInformationCard(package: package),
        ],
      ),
    );
  }

  Color _getEscrowStatusColor(String status) {
    switch (status) {
      case 'held':
        return AppColors.accent;
      case 'released':
        return AppColors.success;
      case 'disputed':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}
