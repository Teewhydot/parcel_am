import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';
import '../../data/repositories/notification_repository_impl.dart';

class NotificationUseCase {
  final repository = NotificationRepositoryImpl();

  /// Watch notifications stream for a specific user
  Stream<Either<Failure, List<NotificationEntity>>> watchNotifications(
    String userId,
  ) {
    return repository.watchNotifications(userId);
  }

  /// Mark a single notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId) {
    return repository.markAsRead(notificationId);
  }

  /// Mark all notifications as read for a user
  Future<Either<Failure, void>> markAllAsRead(String userId) {
    return repository.markAllAsRead(userId);
  }

  /// Delete a specific notification
  Future<Either<Failure, void>> deleteNotification(String notificationId) {
    return repository.deleteNotification(notificationId);
  }

  /// Clear all notifications for a user
  Future<Either<Failure, void>> clearAll(String userId) {
    return repository.clearAll(userId);
  }
}
