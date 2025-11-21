import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class WatchUserParcelsUseCase {
  final ParcelRepository repository;

  WatchUserParcelsUseCase(this.repository);

  Stream<Either<Failure, List<ParcelEntity>>> call(
    String userId, {
    ParcelStatus? status,
  }) {
    return repository.watchUserParcels(userId, status: status);
  }
}
