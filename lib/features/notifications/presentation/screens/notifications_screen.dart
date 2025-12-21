import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/enums/notification_type.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotifications(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllAsRead(widget.userId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () => _showClearAllConfirmation(context),
          ),
        ],
      ),
      body: BlocManager<NotificationBloc, BaseState<NotificationData>>(
        bloc: context.read<NotificationBloc>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: true,
        showResultSuccessNotifications: false,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppText.bodyMedium(state.errorMessage ?? 'An error occurred'),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppButton.primary(
                    onPressed: () {
                      context.read<NotificationBloc>().add(LoadNotifications(widget.userId));
                    },
                    child: AppText.bodyMedium('Retry', color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (state.hasData && state.data != null) {
            final notificationData = state.data!;
            final notifications = notificationData.notifications;

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: AppColors.onSurfaceVariant,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    AppText.titleMedium(
                      'No notifications yet',
                      color: AppColors.onSurfaceVariant,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      'You\'ll see notifications here',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotifications(widget.userId));
              },
              child: _buildGroupedNotificationsList(notifications),
            );
          }

          // Initial or empty state
          return Center(child: AppText.bodyMedium('Loading notifications...'));
        },
        child: Container(),
      ),
    );
  }

  Widget _buildGroupedNotificationsList(List<NotificationEntity> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final todayNotifications = <NotificationEntity>[];
    final yesterdayNotifications = <NotificationEntity>[];
    final thisWeekNotifications = <NotificationEntity>[];
    final earlierNotifications = <NotificationEntity>[];

    for (final notification in notifications) {
      final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      if (notificationDate == today) {
        todayNotifications.add(notification);
      } else if (notificationDate == yesterday) {
        yesterdayNotifications.add(notification);
      } else if (notificationDate.isAfter(thisWeek)) {
        thisWeekNotifications.add(notification);
      } else {
        earlierNotifications.add(notification);
      }
    }

    return AnimationLimiter(
      child: ListView(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            if (todayNotifications.isNotEmpty) ...[
              _buildSectionHeader('Today'),
              ...todayNotifications.map((notification) => _buildNotificationCard(context, notification)),
            ],
            if (yesterdayNotifications.isNotEmpty) ...[
              _buildSectionHeader('Yesterday'),
              ...yesterdayNotifications.map((notification) => _buildNotificationCard(context, notification)),
            ],
            if (thisWeekNotifications.isNotEmpty) ...[
              _buildSectionHeader('This Week'),
              ...thisWeekNotifications.map((notification) => _buildNotificationCard(context, notification)),
            ],
            if (earlierNotifications.isNotEmpty) ...[
              _buildSectionHeader('Earlier'),
              ...earlierNotifications.map((notification) => _buildNotificationCard(context, notification)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AppText.bodySmall(
        title.toUpperCase(),
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationEntity notification) {
    return Slidable(
      key: ValueKey(notification.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              _showDeleteConfirmation(this.context, notification);
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.transparent : AppColors.surfaceVariant,
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
              _buildNotificationIcon(notification.type),
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
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
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

  Widget _buildNotificationIcon(NotificationType type) {
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
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    // Mark notification as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(MarkAsRead(notification.id));
    }

    // Navigate to chat screen if chatId is present
    if (notification.chatId != null && notification.chatId!.isNotEmpty) {
      sl<NavigationService>().navigateTo(
        Routes.chat,
        arguments: {
          'chatId': notification.chatId,
          'otherUserId': notification.senderId ?? '',
          'otherUserName': notification.senderName ?? 'User',
        },
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, NotificationEntity notification) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: AppText.titleMedium('Delete Notification', fontWeight: FontWeight.w600),
        content: AppText.bodyMedium('Are you sure you want to delete this notification?'),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(dialogContext),
            child: AppText.bodyMedium('Cancel', color: AppColors.primary),
          ),
          AppButton.text(
            onPressed: () {
              context.read<NotificationBloc>().add(DeleteNotification(notification.id));
              Navigator.pop(dialogContext);
            },
            child: AppText.bodyMedium('Delete', color: AppColors.error),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: AppText.titleMedium('Clear All Notifications', fontWeight: FontWeight.w600),
        content: AppText.bodyMedium('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(dialogContext),
            child: AppText.bodyMedium('Cancel', color: AppColors.primary),
          ),
          AppButton.text(
            onPressed: () {
              context.read<NotificationBloc>().add(ClearAll(widget.userId));
              Navigator.pop(dialogContext);
            },
            child: AppText.bodyMedium('Clear All', color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
