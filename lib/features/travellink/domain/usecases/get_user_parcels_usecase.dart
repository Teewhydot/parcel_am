import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class GetUserParcelsUseCase {
  final ParcelRepository repository;

  GetUserParcelsUseCase(this.repository);

  Future<Either<Failure, List<ParcelEntity>>> call(
    String userId, {
    ParcelStatus? status,
  }) {
    return repository.getUserParcels(userId, status: status);
  }
}
