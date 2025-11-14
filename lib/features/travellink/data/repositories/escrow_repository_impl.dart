import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/escrow_entity.dart';
import '../../domain/repositories/escrow_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../datasources/escrow_remote_data_source.dart';
import '../../../../core/network/network_info.dart';

class EscrowRepositoryImpl implements EscrowRepository {
  final remoteDataSource = GetIt.instance<EscrowRemoteDataSource>();
  final networkInfo = GetIt.instance<NetworkInfo>();

  @override
  Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(
      String escrowId) async* {
    try {
      await for (final escrowModel
          in remoteDataSource.watchEscrowStatus(escrowId)) {
        yield Right(escrowModel.toEntity());
      }
    } on ServerException {
      yield const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      yield Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, EscrowEntity?>> watchEscrowByParcel(
      String parcelId) async* {
    try {
      await for (final escrowModel
          in remoteDataSource.watchEscrowByParcel(parcelId)) {
        yield Right(escrowModel?.toEntity());
      }
    } on ServerException {
      yield const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      yield Left(UnknownFailure(failureMessage: e.toString()));
    }
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
      if (await networkInfo.isConnected) {
        final escrowModel = await remoteDataSource.createEscrow(
          parcelId,
          senderId,
          travelerId,
          amount,
          currency,
        );
        return Right(escrowModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> holdEscrow(String escrowId) async {
    try {
      if (await networkInfo.isConnected) {
        final escrowModel = await remoteDataSource.holdEscrow(escrowId);
        return Right(escrowModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> releaseEscrow(String escrowId) async {
    try {
      if (await networkInfo.isConnected) {
        final escrowModel = await remoteDataSource.releaseEscrow(escrowId);
        return Right(escrowModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> cancelEscrow(String escrowId, String reason) async {
    try {
      if (await networkInfo.isConnected) {
        final escrowModel = await remoteDataSource.cancelEscrow(escrowId, reason);
        return Right(escrowModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EscrowEntity>> getEscrow(String escrowId) async {
    try {
      if (await networkInfo.isConnected) {
        final escrowModel = await remoteDataSource.getEscrow(escrowId);
        return Right(escrowModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EscrowEntity>>> getUserEscrows(String userId) async {
    try {
      if (await networkInfo.isConnected) {
        final escrowModels = await remoteDataSource.getUserEscrows(userId);
        return Right(escrowModels.map((model) => model.toEntity()).toList());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }
}
