import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl({NotificationRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<NotificationRemoteDataSource>();

  @override
  Stream<Either<Failure, List<NotificationEntity>>> watchNotifications(
    String userId,
  ) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchNotifications(userId).map((notifications) {
        // Map NotificationModel to NotificationEntity
        return notifications
            .map((model) => model as NotificationEntity)
            .toList();
      }),
      operationName: 'watchNotifications',
    );
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.markAsRead(notificationId);
      },
      operationName: 'markAsRead',
    );
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.markAllAsRead(userId);
      },
      operationName: 'markAllAsRead',
    );
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.deleteNotification(notificationId);
      },
      operationName: 'deleteNotification',
    );
  }

  @override
  Future<Either<Failure, void>> clearAll(String userId) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.clearAll(userId);
      },
      operationName: 'clearAll',
    );
  }
}
