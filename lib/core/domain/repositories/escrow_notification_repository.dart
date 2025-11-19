abstract class EscrowNotificationRepository {
  Stream<EscrowNotification> watchUserEscrowNotifications(String userId);
}

class EscrowNotification {
  final String packageId;
  final String packageTitle;
  final String status;
  final DateTime timestamp;

  EscrowNotification({
    required this.packageId,
    required this.packageTitle,
    required this.status,
    required this.timestamp,
  });

  String get message {
    switch (status) {
      case 'held':
        return 'Escrow funds held for $packageTitle';
      case 'released':
        return 'Escrow funds released for $packageTitle';
      case 'disputed':
        return 'Dispute filed for $packageTitle escrow';
      case 'cancelled':
        return 'Escrow cancelled for $packageTitle';
      default:
        return 'Escrow status updated for $packageTitle';
    }
  }
}
