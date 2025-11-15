import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/package_entity.dart';
import '../repositories/package_repository.dart';

class WatchPackage {
  final PackageRepository repository;

  WatchPackage(this.repository);

  Stream<Either<Failure, PackageEntity>> call(String packageId) {
    return repository.watchPackage(packageId);
  }
}
