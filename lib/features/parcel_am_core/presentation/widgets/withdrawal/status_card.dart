import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/withdrawal_order_entity.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.status,
    required this.statusIcon,
    required this.statusColor,
    required this.statusMessage,
    this.showProgress = false,
  });

  final WithdrawalStatus status;
  final IconData statusIcon;
  final Color statusColor;
  final String statusMessage;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingXL,
      child: Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              statusIcon,
              size: 64,
              color: statusColor,
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText(
              status.name.toUpperCase(),
              variant: TextVariant.titleLarge,
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppText.bodyMedium(
              statusMessage,
              textAlign: TextAlign.center,
              color: AppColors.onSurfaceVariant,
            ),
            if (showProgress) ...[
              AppSpacing.verticalSpacing(SpacingSize.md),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
