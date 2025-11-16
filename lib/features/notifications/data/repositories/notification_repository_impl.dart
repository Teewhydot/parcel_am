import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final remoteDataSource = NotificationRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
  final NetworkInfo networkInfo = _NetworkInfoImpl();

  @override
  Stream<Either<Failure, List<NotificationEntity>>> watchNotifications(
    String userId,
  ) {
    return ErrorHandler.handleStream(
      () => remoteDataSource.watchNotifications(userId).map((notifications) {
        // Map NotificationModel to NotificationEntity
        return notifications
            .map((model) => model as NotificationEntity)
            .toList();
      }),
      operationName: 'watchNotifications',
    );
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


class _NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected => InternetConnectionChecker.instance.hasConnection;
}
