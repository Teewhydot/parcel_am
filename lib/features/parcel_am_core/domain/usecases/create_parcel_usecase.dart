import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class CreateParcelUseCase {
  final ParcelRepository _repository;

  CreateParcelUseCase({ParcelRepository? repository})
      : _repository = repository ?? GetIt.instance<ParcelRepository>();

  Future<Either<Failure, ParcelEntity>> call(ParcelEntity parcel) {
    return _repository.createParcel(parcel);
  }
}
