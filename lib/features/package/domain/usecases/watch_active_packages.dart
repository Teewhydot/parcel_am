import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/package_entity.dart';
import '../repositories/package_repository.dart';

class WatchActivePackages {
  final PackageRepository repository;

  WatchActivePackages(this.repository);

  Stream<Either<Failure, List<PackageEntity>>> call(String userId) {
    return repository.watchActivePackages(userId);
  }
}
