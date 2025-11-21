import 'dart:async';
import '../domain/repositories/escrow_notification_repository.dart';
import '../utils/logger.dart';
export '../domain/repositories/escrow_notification_repository.dart';

class NotificationService {
  final EscrowNotificationRepository _repository;
  StreamSubscription? _escrowNotificationSubscription;
  final _notificationController = StreamController<EscrowNotification>.broadcast();

  NotificationService({required EscrowNotificationRepository repository})
      : _repository = repository;

  Stream<EscrowNotification> get escrowNotifications => _notificationController.stream;

  void subscribeToEscrowNotifications(String userId) {
    _escrowNotificationSubscription?.cancel();

    _escrowNotificationSubscription = _repository
        .watchUserEscrowNotifications(userId)
        .listen(
      (notification) {
        _notificationController.add(notification);
      },
      onError: (error) {
        Logger.logError('Repository Error (EscrowNotifications): $error', tag: 'EscrowNotificationService');
      },
    );
  }

  void unsubscribe() {
    _escrowNotificationSubscription?.cancel();
  }

  void dispose() {
    _escrowNotificationSubscription?.cancel();
    _notificationController.close();
  }
}

// Re-export or redefine EscrowNotification if it's not in the repository file.
// In step 210, I defined EscrowNotification in the repository file.
// So I should probably remove it from here if it's already there, or import it.
// Let's check the repository file content first to be sure.

