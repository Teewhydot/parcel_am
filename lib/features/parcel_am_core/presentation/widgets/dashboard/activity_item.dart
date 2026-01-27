import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_icon.dart';

class ActivityItem extends StatelessWidget {
  const ActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.icon,
    this.hasAvatar = false,
    this.avatarText = '',
    this.escrowStatus,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData? icon;
  final bool hasAvatar;
  final String avatarText;
  final String? escrowStatus;
  final VoidCallback? onTap;

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

  IconData _getEscrowStatusIcon(String status) {
    switch (status) {
      case 'held':
        return Icons.lock;
      case 'released':
        return Icons.check_circle;
      case 'disputed':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      margin: EdgeInsets.only(bottom: SpacingSize.md.value),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              if (!hasAvatar)
                AppIcon.filled(
                  icon: icon ?? Icons.inventory_2_outlined,
                  size: IconSize.small,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                )
              else
                AppContainer(
                  width: 40,
                  height: 40,
                  variant: ContainerVariant.surface,
                  color: AppColors.primary,
                  borderRadius: AppRadius.xl,
                  alignment: Alignment.center,
                  child: AppText.labelSmall(
                    avatarText,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              AppSpacing.horizontalSpacing(SpacingSize.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(title, fontWeight: FontWeight.w600),
                    AppText.bodySmall(
                      subtitle,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppContainer(
                variant: ContainerVariant.filled,
                color: statusColor.withValues(alpha: 0.1),
                padding: EdgeInsets.symmetric(
                  horizontal: SpacingSize.sm.value,
                  vertical: SpacingSize.xs.value,
                ),
                borderRadius: AppRadius.md,
                child: AppText.labelSmall(
                  status,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (escrowStatus != null) ...[
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppContainer(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingSize.sm.value,
                vertical: SpacingSize.xs.value,
              ),
              color: _getEscrowStatusColor(escrowStatus!).withValues(alpha: 0.1),
              borderRadius: AppRadius.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEscrowStatusIcon(escrowStatus!),
                    size: 14,
                    color: _getEscrowStatusColor(escrowStatus!),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.xs),
                  AppText.labelSmall(
                    'Escrow: ${escrowStatus!.toUpperCase()}',
                    color: _getEscrowStatusColor(escrowStatus!),
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
