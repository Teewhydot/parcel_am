import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import 'package:parcel_am/features/notifications/presentation/bloc/notification_cubit.dart';
import 'notification_settings_screen.dart';
import '../widgets/notifications/notification_empty_state.dart';
import '../widgets/notifications/notification_error_state.dart';
import '../widgets/notifications/notification_card.dart';
import '../widgets/notifications/notification_section_header.dart';
import '../widgets/notifications/notification_dialogs.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationSettingsScreen(userId: widget.userId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<NotificationCubit>().markAllAsRead(widget.userId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () => NotificationClearAllDialog.show(
              context,
              onConfirm: () =>
                  context.read<NotificationCubit>().clearAll(widget.userId),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Either<Failure, List<NotificationEntity>>>(
        stream:
            context.read<NotificationCubit>().watchNotifications(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return NotificationErrorState(
              message: 'An error occurred',
              onRetry: () => setState(() {}),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return snapshot.data!.fold(
            (failure) => NotificationErrorState(message: failure.failureMessage),
            (notifications) {
              if (notifications.isEmpty) {
                return const NotificationEmptyState();
              }
              return _GroupedNotificationsList(
                notifications: notifications,
                onNotificationTap: _handleNotificationTap,
                onNotificationDelete: _handleNotificationDelete,
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    if (!notification.isRead) {
      context.read<NotificationCubit>().markAsRead(notification.id);
    }

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

  void _handleNotificationDelete(NotificationEntity notification) {
    NotificationDeleteDialog.show(
      context,
      onConfirm: () =>
          context.read<NotificationCubit>().deleteNotification(notification.id),
    );
  }
}

class _GroupedNotificationsList extends StatelessWidget {
  const _GroupedNotificationsList({
    required this.notifications,
    required this.onNotificationTap,
    required this.onNotificationDelete,
  });

  final List<NotificationEntity> notifications;
  final void Function(NotificationEntity) onNotificationTap;
  final void Function(NotificationEntity) onNotificationDelete;

  @override
  Widget build(BuildContext context) {
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
            child: FadeInAnimation(child: widget),
          ),
          children: [
            if (todayNotifications.isNotEmpty) ...[
              const NotificationSectionHeader(title: 'Today'),
              ...todayNotifications.map(
                (notification) => NotificationCard(
                  notification: notification,
                  onTap: () => onNotificationTap(notification),
                  onDelete: () => onNotificationDelete(notification),
                ),
              ),
            ],
            if (yesterdayNotifications.isNotEmpty) ...[
              const NotificationSectionHeader(title: 'Yesterday'),
              ...yesterdayNotifications.map(
                (notification) => NotificationCard(
                  notification: notification,
                  onTap: () => onNotificationTap(notification),
                  onDelete: () => onNotificationDelete(notification),
                ),
              ),
            ],
            if (thisWeekNotifications.isNotEmpty) ...[
              const NotificationSectionHeader(title: 'This Week'),
              ...thisWeekNotifications.map(
                (notification) => NotificationCard(
                  notification: notification,
                  onTap: () => onNotificationTap(notification),
                  onDelete: () => onNotificationDelete(notification),
                ),
              ),
            ],
            if (earlierNotifications.isNotEmpty) ...[
              const NotificationSectionHeader(title: 'Earlier'),
              ...earlierNotifications.map(
                (notification) => NotificationCard(
                  notification: notification,
                  onTap: () => onNotificationTap(notification),
                  onDelete: () => onNotificationDelete(notification),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
