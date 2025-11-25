import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';

abstract class ParcelRepository {
  Stream<Either<Failure, ParcelEntity>> watchParcelStatus(String parcelId);

  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(
    String userId, {
    ParcelStatus? status,
  });

  /// Watches parcels where the current user is the traveler (courier).
  /// Returns a stream of parcels filtered by travelerId and ordered by
  /// lastStatusUpdate in descending order (most recent first).
  ///
  /// This stream provides real-time updates for the "My Deliveries" tab,
  /// showing all parcels that the courier has accepted for delivery.
  ///
  /// Query filters: where travelerId equals userId
  /// Ordering: by lastStatusUpdate descending
  /// Requires composite index: (travelerId, lastStatusUpdate)
  Stream<Either<Failure, List<ParcelEntity>>> watchUserAcceptedParcels(
    String userId,
  );

  Future<Either<Failure, ParcelEntity>> createParcel(ParcelEntity parcel);

  Future<Either<Failure, ParcelEntity>> getParcel(String parcelId);

  Future<Either<Failure, ParcelEntity>> updateParcelStatus(
    String parcelId,
    ParcelStatus status,
  );

  Future<Either<Failure, ParcelEntity>> updateParcel(
    String parcelId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ParcelEntity>> assignTraveler(
    String parcelId,
    String travelerId,
  );

  Future<Either<Failure, List<ParcelEntity>>> getUserParcels(
    String userId, {
    ParcelStatus? status,
  });

  Future<Either<Failure, List<ParcelEntity>>> getParcelsByUser(String userId);

  Future<Either<Failure, List<ParcelEntity>>> getAvailableParcels();

  Stream<Either<Failure, List<ParcelEntity>>> watchAvailableParcels();
}
