import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/presence_entity.dart';
import '../../domain/repositories/presence_repository.dart';
import '../datasources/presence_remote_data_source.dart';

class PresenceRepositoryImpl implements PresenceRepository {
  final PresenceRemoteDataSource remoteDataSource;

  PresenceRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Stream<Either<Failure, PresenceEntity>> watchUserPresence(String userId) {
    return ErrorHandler.handleStream(
      () => remoteDataSource.watchUserPresence(userId).map((presence) {
        return presence.toEntity();
      }),
      operationName: 'watchUserPresence',
    );
  }

  @override
  Future<Either<Failure, void>> updatePresenceStatus(String userId, PresenceStatus status) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.updatePresenceStatus(userId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTypingStatus(
    String userId,
    String? chatId,
    bool isTyping,
  ) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.updateTypingStatus(userId, chatId, isTyping);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastSeen(String userId) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.updateLastSeen(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PresenceEntity?>> getUserPresence(String userId) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      final presence = await remoteDataSource.getUserPresence(userId);
      return Right(presence?.toEntity());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }
}
