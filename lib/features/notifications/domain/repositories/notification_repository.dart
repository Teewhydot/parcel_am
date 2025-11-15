import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Watch notifications stream for a specific user
  /// Returns a stream of Either<Failure, List<NotificationEntity>>
  Stream<Either<Failure, List<NotificationEntity>>> watchNotifications(
    String userId,
  );

  /// Mark a single notification as read
  /// Returns Either<Failure, void> indicating success or failure
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read for a user
  /// Returns Either<Failure, void> indicating success or failure
  Future<Either<Failure, void>> markAllAsRead(String userId);

  /// Delete a specific notification
  /// Returns Either<Failure, void> indicating success or failure
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Clear all notifications for a user
  /// Returns Either<Failure, void> indicating success or failure
  Future<Either<Failure, void>> clearAll(String userId);
}
