import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/escrow_entity.dart';
import '../../domain/repositories/escrow_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/exceptions/custom_exceptions.dart';
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
  ) async {
    try {
       final escrowModel = await _remoteDataSource.createEscrow(
          parcelId,
          senderId,
          travelerId,
          amount,
          currency,
        );
        return Right(escrowModel.toEntity());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> holdEscrow(String escrowId) async {
    try {
    final escrowModel = await _remoteDataSource.holdEscrow(escrowId);
        return Right(escrowModel.toEntity());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> releaseEscrow(String escrowId) async {
    try {
     final escrowModel = await _remoteDataSource.releaseEscrow(escrowId);
        return Right(escrowModel.toEntity());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> cancelEscrow(String escrowId, String reason) async {
    try {
     final escrowModel = await _remoteDataSource.cancelEscrow(escrowId, reason);
        return Right(escrowModel.toEntity());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> getEscrow(String escrowId) async {
    try {
    final escrowModel = await _remoteDataSource.getEscrow(escrowId);
        return Right(escrowModel.toEntity());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EscrowEntity>>> getUserEscrows(String userId) async {
    try {
     final escrowModels = await _remoteDataSource.getUserEscrows(userId);
        return Right(escrowModels.map((model) => model.toEntity()).toList());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }
}
