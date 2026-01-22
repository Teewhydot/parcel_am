import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../datasources/parcel_remote_data_source.dart';
import '../models/parcel_model.dart';

class ParcelRepositoryImpl implements ParcelRepository {
  final ParcelRemoteDataSource _remoteDataSource;

  ParcelRepositoryImpl({ParcelRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<ParcelRemoteDataSource>();

  @override
  Stream<Either<Failure, ParcelEntity>> watchParcelStatus(String parcelId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchParcelStatus(parcelId).map((parcelModel) {
        return parcelModel.toEntity();
      }),
      operationName: 'watchParcelStatus',
    );
  }

  @override
  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(
    String userId, {
    ParcelStatus? status,
  }) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource
          .watchUserParcels(userId, status: status)
          .map((parcelModels) {
            return parcelModels.map((model) => model.toEntity()).toList();
          }),
      operationName: 'watchUserParcels',
    );
  }

  @override
  Stream<Either<Failure, List<ParcelEntity>>> watchUserAcceptedParcels(
    String userId,
  ) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource
          .watchUserAcceptedParcels(userId)
          .map((parcelModels) {
            return parcelModels.map((model) => model.toEntity()).toList();
          }),
      operationName: 'watchUserAcceptedParcels',
    );
  }

  @override
  Future<Either<Failure, ParcelEntity>> createParcel(
    ParcelEntity parcel,
  ) async {
    try {
      final parcelModel = ParcelModel.fromEntity(parcel);
      final createdModel = await _remoteDataSource.createParcel(parcelModel);
      return Right(createdModel.toEntity());
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
      final parcelModel = await _remoteDataSource.updateParcel(parcelId, data);
      return Right(parcelModel.toEntity());
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
      final parcelModel = await _remoteDataSource.updateParcelStatus(
        parcelId,
        status,
      );
      return Right(parcelModel.toEntity());
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
      final parcelModel = await _remoteDataSource.assignTraveler(
        parcelId,
        travelerId,
      );
      return Right(parcelModel.toEntity());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParcelEntity>> getParcel(String parcelId) async {
    try {
      final parcelModel = await _remoteDataSource.getParcel(parcelId);
      return Right(parcelModel.toEntity());
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
      final parcelModels = await _remoteDataSource.getUserParcels(
        userId,
        status: status,
      );
      return Right(parcelModels.map((model) => model.toEntity()).toList());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParcelEntity>>> getParcelsByUser(
    String userId,
  ) async {
    try {
      final parcelModels = await _remoteDataSource.getParcelsByUser(userId);
      return Right(parcelModels.map((model) => model.toEntity()).toList());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParcelEntity>>> getAvailableParcels() async {
    try {
      final parcelModels = await _remoteDataSource.getAvailableParcels();
      return Right(parcelModels.map((model) => model.toEntity()).toList());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ParcelEntity>>> watchAvailableParcels() {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchAvailableParcels().map((parcelModels) {
        return parcelModels.map((model) => model.toEntity()).toList();
      }),
      operationName: 'watchAvailableParcels',
    );
  }
}
