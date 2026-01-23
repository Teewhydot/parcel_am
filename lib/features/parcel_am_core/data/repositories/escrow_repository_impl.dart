import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/escrow_entity.dart';
import '../../domain/repositories/escrow_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../datasources/escrow_remote_data_source.dart';

class EscrowRepositoryImpl implements EscrowRepository {
  final EscrowRemoteDataSource _remoteDataSource;

  EscrowRepositoryImpl({EscrowRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<EscrowRemoteDataSource>();

  @override
  Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(String escrowId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchEscrowStatus(escrowId).map((escrowModel) {
        return escrowModel.toEntity();
      }),
      operationName: 'watchEscrowStatus',
    );
  }

  @override
  Stream<Either<Failure, EscrowEntity?>> watchEscrowByParcel(String parcelId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchEscrowByParcel(parcelId).map((escrowModel) {
        return escrowModel?.toEntity();
      }),
      operationName: 'watchEscrowByParcel',
    );
  }

  @override
  Future<Either<Failure, EscrowEntity>> createEscrow(
    String parcelId,
    String senderId,
    String travelerId,
    double amount,
    String currency,
  ) {
    return ErrorHandler.handle(
      () async {
        final escrowModel = await _remoteDataSource.createEscrow(
          parcelId,
          senderId,
          travelerId,
          amount,
          currency,
        );
        return escrowModel.toEntity();
      },
      operationName: 'createEscrow',
    );
  }

  @override
  Future<Either<Failure, EscrowEntity>> holdEscrow(String escrowId) {
    return ErrorHandler.handle(
      () async {
        final escrowModel = await _remoteDataSource.holdEscrow(escrowId);
        return escrowModel.toEntity();
      },
      operationName: 'holdEscrow',
    );
  }

  @override
  Future<Either<Failure, EscrowEntity>> releaseEscrow(String escrowId) {
    return ErrorHandler.handle(
      () async {
        final escrowModel = await _remoteDataSource.releaseEscrow(escrowId);
        return escrowModel.toEntity();
      },
      operationName: 'releaseEscrow',
    );
  }

  @override
  Future<Either<Failure, EscrowEntity>> cancelEscrow(String escrowId, String reason) {
    return ErrorHandler.handle(
      () async {
        final escrowModel = await _remoteDataSource.cancelEscrow(escrowId, reason);
        return escrowModel.toEntity();
      },
      operationName: 'cancelEscrow',
    );
  }

  @override
  Future<Either<Failure, EscrowEntity>> getEscrow(String escrowId) {
    return ErrorHandler.handle(
      () async {
        final escrowModel = await _remoteDataSource.getEscrow(escrowId);
        return escrowModel.toEntity();
      },
      operationName: 'getEscrow',
    );
  }

  @override
  Future<Either<Failure, List<EscrowEntity>>> getUserEscrows(String userId) {
    return ErrorHandler.handle(
      () async {
        final escrowModels = await _remoteDataSource.getUserEscrows(userId);
        return escrowModels.map((model) => model.toEntity()).toList();
      },
      operationName: 'getUserEscrows',
    );
  }
}
