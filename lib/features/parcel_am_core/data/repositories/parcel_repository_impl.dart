import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
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
  ) {
    return ErrorHandler.handle(
      () async {
        final parcelModel = ParcelModel.fromEntity(parcel);
        final createdModel = await _remoteDataSource.createParcel(parcelModel);
        return createdModel.toEntity();
      },
      operationName: 'createParcel',
    );
  }

  @override
  Future<Either<Failure, ParcelEntity>> updateParcel(
    String parcelId,
    Map<String, dynamic> data,
  ) {
    return ErrorHandler.handle(
      () async {
        final parcelModel = await _remoteDataSource.updateParcel(parcelId, data);
        return parcelModel.toEntity();
      },
      operationName: 'updateParcel',
    );
  }

  @override
  Future<Either<Failure, ParcelEntity>> updateParcelStatus(
    String parcelId,
    ParcelStatus status,
  ) {
    return ErrorHandler.handle(
      () async {
        final parcelModel = await _remoteDataSource.updateParcelStatus(
          parcelId,
          status,
        );
        return parcelModel.toEntity();
      },
      operationName: 'updateParcelStatus',
    );
  }

  @override
  Future<Either<Failure, ParcelEntity>> assignTraveler(
    String parcelId,
    String travelerId,
  ) {
    return ErrorHandler.handle(
      () async {
        final parcelModel = await _remoteDataSource.assignTraveler(
          parcelId,
          travelerId,
        );
        return parcelModel.toEntity();
      },
      operationName: 'assignTraveler',
    );
  }

  @override
  Future<Either<Failure, ParcelEntity>> getParcel(String parcelId) {
    return ErrorHandler.handle(
      () async {
        final parcelModel = await _remoteDataSource.getParcel(parcelId);
        return parcelModel.toEntity();
      },
      operationName: 'getParcel',
    );
  }

  @override
  Future<Either<Failure, List<ParcelEntity>>> getUserParcels(
    String userId, {
    ParcelStatus? status,
  }) {
    return ErrorHandler.handle(
      () async {
        final parcelModels = await _remoteDataSource.getUserParcels(
          userId,
          status: status,
        );
        return parcelModels.map((model) => model.toEntity()).toList();
      },
      operationName: 'getUserParcels',
    );
  }

  @override
  Future<Either<Failure, List<ParcelEntity>>> getParcelsByUser(
    String userId,
  ) {
    return ErrorHandler.handle(
      () async {
        final parcelModels = await _remoteDataSource.getParcelsByUser(userId);
        return parcelModels.map((model) => model.toEntity()).toList();
      },
      operationName: 'getParcelsByUser',
    );
  }

  @override
  Future<Either<Failure, List<ParcelEntity>>> getAvailableParcels() {
    return ErrorHandler.handle(
      () async {
        final parcelModels = await _remoteDataSource.getAvailableParcels();
        return parcelModels.map((model) => model.toEntity()).toList();
      },
      operationName: 'getAvailableParcels',
    );
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
