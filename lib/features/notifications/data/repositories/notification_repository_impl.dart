import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, List<NotificationEntity>>> watchNotifications(
    String userId,
  ) async* {
    if (!await networkInfo.isConnected) {
      yield const Left(NetworkFailure(failureMessage: 'No internet connection'));
      return;
    }

    try {
      await for (final notifications in remoteDataSource.watchNotifications(userId)) {
        // Map NotificationModel to NotificationEntity
        final entities = notifications
            .map((model) => model as NotificationEntity)
            .toList();
        yield Right(entities);
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.markAllAsRead(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.deleteNotification(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.clearAll(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }
}
