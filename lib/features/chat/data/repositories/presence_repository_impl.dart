import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/presence_entity.dart';
import '../../domain/repositories/presence_repository.dart';
import '../datasources/presence_remote_data_source.dart';

class PresenceRepositoryImpl implements PresenceRepository {
  final PresenceRemoteDataSource _remoteDataSource;

  PresenceRepositoryImpl({PresenceRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<PresenceRemoteDataSource>();

  @override
  Future<Either<Failure, void>> setOnline(String userId) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.updatePresenceStatus(userId, PresenceStatus.online);
      },
      operationName: 'setOnline',
    );
  }

  @override
  Future<Either<Failure, void>> setOffline(String userId) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.updatePresenceStatus(userId, PresenceStatus.offline);
      },
      operationName: 'setOffline',
    );
  }

  @override
  Future<Either<Failure, void>> updateLastSeen(String userId) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.updateLastSeen(userId);
      },
      operationName: 'updateLastSeen',
    );
  }
}
