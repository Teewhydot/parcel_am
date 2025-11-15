enum NotificationType {
  chatMessage,
  systemAlert,
  announcement,
  reminder,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.chatMessage:
        return 'chat_message';
      case NotificationType.systemAlert:
        return 'system_alert';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.reminder:
        return 'reminder';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'chat_message':
        return NotificationType.chatMessage;
      case 'system_alert':
        return NotificationType.systemAlert;
      case 'announcement':
        return NotificationType.announcement;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.chatMessage;
    }
  }
}
