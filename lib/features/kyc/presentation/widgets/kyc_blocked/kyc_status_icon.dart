import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/kyc_status.dart';

class KycStatusIcon extends StatelessWidget {
  final KycStatus status;

  const KycStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    switch (status) {
      case KycStatus.notStarted:
        icon = Icons.verified_user_outlined;
        color = AppColors.warning;
        break;
      case KycStatus.incomplete:
        icon = Icons.info_outlined;
        color = AppColors.warning;
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        icon = Icons.pending_outlined;
        color = AppColors.primary;
        break;
      case KycStatus.rejected:
        icon = Icons.cancel_outlined;
        color = AppColors.error;
        break;
      case KycStatus.approved:
        icon = Icons.verified;
        color = AppColors.success;
        break;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: color,
      ),
    );
  }
}
