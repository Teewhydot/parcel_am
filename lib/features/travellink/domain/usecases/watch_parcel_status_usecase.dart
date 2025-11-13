import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class WatchParcelStatusUseCase {
  final ParcelRepository repository;

  WatchParcelStatusUseCase(this.repository);

  Stream<Either<Failure, ParcelEntity>> call(String parcelId) {
    return repository.watchParcelStatus(parcelId);
  }
}
