import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class NotificationUseCase {
  final NotificationRepository _repository;

  NotificationUseCase({NotificationRepository? repository})
      : _repository = repository ?? GetIt.instance<NotificationRepository>();

  /// Watch notifications stream for a specific user
  Stream<Either<Failure, List<NotificationEntity>>> watchNotifications(
    String userId,
  ) {
    return _repository.watchNotifications(userId);
  }

  /// Mark a single notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId) {
    return _repository.markAsRead(notificationId);
  }

  /// Mark all notifications as read for a user
  Future<Either<Failure, void>> markAllAsRead(String userId) {
    return _repository.markAllAsRead(userId);
  }

  /// Delete a specific notification
  Future<Either<Failure, void>> deleteNotification(String notificationId) {
    return _repository.deleteNotification(notificationId);
  }

  /// Clear all notifications for a user
  Future<Either<Failure, void>> clearAll(String userId) {
    return _repository.clearAll(userId);
  }
}
