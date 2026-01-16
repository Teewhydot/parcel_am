enum NotificationType {
  chatMessage,
  systemAlert,
  announcement,
  reminder,
  parcelRequestAccepted,
  deliveryConfirmationRequired,
  escrowHeld,
  escrowReleased,
  escrowDisputed,
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
      case NotificationType.parcelRequestAccepted:
        return 'parcel_request_accepted';
      case NotificationType.deliveryConfirmationRequired:
        return 'delivery_confirmation_required';
      case NotificationType.escrowHeld:
        return 'escrow_held';
      case NotificationType.escrowReleased:
        return 'escrow_released';
      case NotificationType.escrowDisputed:
        return 'escrow_disputed';
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
      case 'parcel_request_accepted':
        return NotificationType.parcelRequestAccepted;
      case 'delivery_confirmation_required':
        return NotificationType.deliveryConfirmationRequired;
      case 'escrow_held':
        return NotificationType.escrowHeld;
      case 'escrow_released':
        return NotificationType.escrowReleased;
      case 'escrow_disputed':
        return NotificationType.escrowDisputed;
      default:
        return NotificationType.chatMessage;
    }
  }
}
