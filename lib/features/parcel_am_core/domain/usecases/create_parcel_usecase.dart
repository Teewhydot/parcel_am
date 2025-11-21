import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class CreateParcelUseCase {
  final ParcelRepository repository;

  CreateParcelUseCase(this.repository);

  Future<Either<Failure, ParcelEntity>> call(ParcelEntity parcel) {
    return repository.createParcel(parcel);
  }
}
