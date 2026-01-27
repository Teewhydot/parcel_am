import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/enums/notification_type.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(notification.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.transparent
                : AppColors.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: AppColors.outline,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.type),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            notification.title,
                            variant: TextVariant.titleSmall,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    AppText.bodyMedium(
                      notification.body,
                      color: AppColors.textSecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    AppText.bodySmall(
                      timeago.format(notification.timestamp),
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.chatMessage:
        icon = Icons.message;
        color = AppColors.primary;
        break;
      case NotificationType.systemAlert:
        icon = Icons.info;
        color = AppColors.info;
        break;
      case NotificationType.announcement:
        icon = Icons.campaign;
        color = AppColors.warning;
        break;
      case NotificationType.reminder:
        icon = Icons.notifications;
        color = AppColors.secondary;
        break;
      default:
        icon = Icons.notifications_none;
        color = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }
}
