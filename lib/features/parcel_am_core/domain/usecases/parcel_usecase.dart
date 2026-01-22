import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class ParcelUseCase {
  final ParcelRepository _repository;

  ParcelUseCase({ParcelRepository? repository})
      : _repository = repository ?? GetIt.instance<ParcelRepository>();

  Future<Either<Failure, ParcelEntity>> createParcel(ParcelEntity parcel) {
    return _repository.createParcel(parcel);
  }

  Future<Either<Failure, ParcelEntity>> updateParcelStatus(
    String parcelId,
    ParcelStatus status,
  ) {
    return _repository.updateParcelStatus(parcelId, status);
  }

  Future<Either<Failure, ParcelEntity>> getParcel(String parcelId) {
    return _repository.getParcel(parcelId);
  }

  Stream<Either<Failure, ParcelEntity>> watchParcelStatus(String parcelId) {
    return _repository.watchParcelStatus(parcelId);
  }

  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(String userId) {
    return _repository.watchUserParcels(userId);
  }

  /// Watches parcels where the given user is the assigned traveler/courier.
  ///
  /// This stream provides real-time updates for parcels that the user has
  /// accepted for delivery. The parcels are filtered by travelerId matching
  /// the provided userId.
  ///
  /// Returns a stream of Either<Failure, List<ParcelEntity>>
  /// - Left: Failure if there's an error fetching or watching the parcels
  /// - Right: List of ParcelEntity where the user is the traveler
  Stream<Either<Failure, List<ParcelEntity>>> watchUserAcceptedParcels(String userId) {
    return _repository.watchUserAcceptedParcels(userId);
  }

  Future<Either<Failure, List<ParcelEntity>>> getUserParcels(String userId) {
    return _repository.getUserParcels(userId);
  }

  Future<Either<Failure, List<ParcelEntity>>> getAvailableParcels() {
    return _repository.getAvailableParcels();
  }

  Stream<Either<Failure, List<ParcelEntity>>> watchAvailableParcels() {
    return _repository.watchAvailableParcels();
  }

  Future<Either<Failure, ParcelEntity>> assignTraveler(
    String parcelId,
    String travelerId,
  ) {
    return _repository.assignTraveler(parcelId, travelerId);
  }
}
