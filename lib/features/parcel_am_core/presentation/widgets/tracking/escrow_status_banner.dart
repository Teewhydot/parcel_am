import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../domain/entities/package_entity.dart';

class EscrowStatusBanner extends StatelessWidget {
  const EscrowStatusBanner({super.key, required this.package});

  final PackageEntity package;

  @override
  Widget build(BuildContext context) {
    final paymentInfo = package.paymentInfo;
    if (paymentInfo == null || !paymentInfo.isEscrow) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (paymentInfo.escrowStatus) {
      case 'held':
        statusColor = AppColors.accent;
        statusIcon = Icons.lock;
        statusText = 'Escrow Held - ₦${paymentInfo.amount.toStringAsFixed(2)}';
      case 'released':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Escrow Released - ₦${paymentInfo.amount.toStringAsFixed(2)}';
      case 'disputed':
        statusColor = AppColors.error;
        statusIcon = Icons.warning;
        statusText = 'Escrow Disputed - Under Review';
      case 'cancelled':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.cancel;
        statusText = 'Escrow Cancelled';
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Escrow Pending';
    }

    return AppContainer(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingLG.left,
        vertical: AppSpacing.paddingSM.top,
      ),
      padding: AppSpacing.paddingMD,
      color: statusColor.withValues(alpha: 0.1),
      borderRadius: AppRadius.md,
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(statusText, color: statusColor, fontWeight: FontWeight.bold),
                if (paymentInfo.escrowHeldAt != null)
                  AppText.bodySmall('Since ${_formatDate(paymentInfo.escrowHeldAt!)}', color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}
