import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../datasources/parcel_remote_data_source.dart';
import '../models/parcel_model.dart';
import '../../../../core/network/network_info.dart';

class ParcelRepositoryImpl implements ParcelRepository {
  final remoteDataSource = GetIt.instance<ParcelRemoteDataSource>();
  final networkInfo = GetIt.instance<NetworkInfo>();

  @override
  Stream<Either<Failure, ParcelEntity>> watchParcelStatus(
      String parcelId) async* {
    try {
      await for (final parcelModel
          in remoteDataSource.watchParcelStatus(parcelId)) {
        yield Right(parcelModel.toEntity());
      }
    } on ServerException {
      yield const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      yield Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(
      String userId, {ParcelStatus? status}) async* {
    try {
      await for (final parcelModels
          in remoteDataSource.watchUserParcels(userId, status: status)) {
        yield Right(parcelModels.map((model) => model.toEntity()).toList());
      }
    } on ServerException {
      yield const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      yield Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParcelEntity>> createParcel(
      ParcelEntity parcel) async {
    try {
      if (await networkInfo.isConnected) {
        final parcelModel = ParcelModel.fromEntity(parcel);
        final createdModel = await remoteDataSource.createParcel(parcelModel);
        return Right(createdModel.toEntity());
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
  Future<Either<Failure, ParcelEntity>> updateParcel(
    String parcelId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final parcelModel =
            await remoteDataSource.updateParcel(parcelId, data);
        return Right(parcelModel.toEntity());
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
  Future<Either<Failure, ParcelEntity>> updateParcelStatus(
    String parcelId,
    ParcelStatus status,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final parcelModel =
            await remoteDataSource.updateParcelStatus(parcelId, status);
        return Right(parcelModel.toEntity());
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
  Future<Either<Failure, ParcelEntity>> assignTraveler(
    String parcelId,
    String travelerId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final parcelModel =
            await remoteDataSource.assignTraveler(parcelId, travelerId);
        return Right(parcelModel.toEntity());
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
  Future<Either<Failure, ParcelEntity>> getParcel(String parcelId) async {
    try {
      if (await networkInfo.isConnected) {
        final parcelModel = await remoteDataSource.getParcel(parcelId);
        return Right(parcelModel.toEntity());
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
  Future<Either<Failure, List<ParcelEntity>>> getUserParcels(
    String userId, {
    ParcelStatus? status,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final parcelModels = await remoteDataSource.getUserParcels(userId, status: status);
        return Right(parcelModels.map((model) => model.toEntity()).toList());
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
  Future<Either<Failure, List<ParcelEntity>>> getParcelsByUser(
      String userId) async {
    try {
      if (await networkInfo.isConnected) {
        final parcelModels = await remoteDataSource.getParcelsByUser(userId);
        return Right(parcelModels.map((model) => model.toEntity()).toList());
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
