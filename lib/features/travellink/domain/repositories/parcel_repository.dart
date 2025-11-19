import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';

abstract class ParcelRepository {
  Stream<Either<Failure, ParcelEntity>> watchParcelStatus(String parcelId);

  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(
    String userId, {
    ParcelStatus? status,
  });

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
