import '../../domain/entities/notification_entity.dart';

/// Data model for notification state
class NotificationData {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationData({
    required this.notifications,
    required this.unreadCount,
  });

  NotificationData copyWith({
    List<NotificationEntity>? notifications,
    int? unreadCount,
  }) {
    return NotificationData(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
