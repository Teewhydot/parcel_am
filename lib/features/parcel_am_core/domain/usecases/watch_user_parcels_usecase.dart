import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class WatchUserParcelsUseCase {
  final ParcelRepository _repository;

  WatchUserParcelsUseCase({ParcelRepository? repository})
      : _repository = repository ?? GetIt.instance<ParcelRepository>();

  Stream<Either<Failure, List<ParcelEntity>>> call(
    String userId, {
    ParcelStatus? status,
  }) {
    return _repository.watchUserParcels(userId, status: status);
  }
}
