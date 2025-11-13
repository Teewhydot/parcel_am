import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class UpdateParcelStatusUseCase {
  final ParcelRepository repository;

  UpdateParcelStatusUseCase(this.repository);

  Future<Either<Failure, ParcelEntity>> call(
    String parcelId,
    ParcelStatus status,
  ) {
    return repository.updateParcelStatus(parcelId, status);
  }
}
