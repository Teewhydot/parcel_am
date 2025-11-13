import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class GetParcelUseCase {
  final ParcelRepository repository;

  GetParcelUseCase(this.repository);

  Future<Either<Failure, ParcelEntity>> call(String parcelId) {
    return repository.getParcel(parcelId);
  }
}
