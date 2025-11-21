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
