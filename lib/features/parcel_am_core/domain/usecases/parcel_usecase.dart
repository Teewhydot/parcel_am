import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../../data/repositories/parcel_repository_impl.dart';

class ParcelUseCase {
  final repository = ParcelRepositoryImpl();

  Future<Either<Failure, ParcelEntity>> createParcel(ParcelEntity parcel) {
    return repository.createParcel(parcel);
  }

  Future<Either<Failure, ParcelEntity>> updateParcelStatus(
    String parcelId,
    ParcelStatus status,
  ) {
    return repository.updateParcelStatus(parcelId, status);
  }

  Future<Either<Failure, ParcelEntity>> getParcel(String parcelId) {
    return repository.getParcel(parcelId);
  }

  Stream<Either<Failure, ParcelEntity>> watchParcelStatus(String parcelId) {
    return repository.watchParcelStatus(parcelId);
  }

  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(String userId) {
    return repository.watchUserParcels(userId);
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
  ///
  /// Note: This method will be fully implemented in Task Group 2.4.
  /// For now, it's a stub that delegates to the repository method.
  Stream<Either<Failure, List<ParcelEntity>>> watchUserAcceptedParcels(String userId) {
    return repository.watchUserAcceptedParcels(userId);
  }

  Future<Either<Failure, List<ParcelEntity>>> getUserParcels(String userId) {
    return repository.getUserParcels(userId);
  }

  Future<Either<Failure, List<ParcelEntity>>> getAvailableParcels() {
    return repository.getAvailableParcels();
  }

  Stream<Either<Failure, List<ParcelEntity>>> watchAvailableParcels() {
    return repository.watchAvailableParcels();
  }

  Future<Either<Failure, ParcelEntity>> assignTraveler(
    String parcelId,
    String travelerId,
  ) {
    return repository.assignTraveler(parcelId, travelerId);
  }
}
