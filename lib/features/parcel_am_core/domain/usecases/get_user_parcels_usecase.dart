import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class GetUserParcelsUseCase {
  final ParcelRepository _repository;

  GetUserParcelsUseCase({ParcelRepository? repository})
      : _repository = repository ?? GetIt.instance<ParcelRepository>();

  Future<Either<Failure, List<ParcelEntity>>> call(
    String userId, {
    ParcelStatus? status,
  }) {
    return _repository.getUserParcels(userId, status: status);
  }
}
