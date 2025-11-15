import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/package_entity.dart';
import '../../data/repositories/package_repository_impl.dart';

class WatchPackage {
  final repository = PackageRepositoryImpl();

  Stream<Either<Failure, PackageEntity>> call(String packageId) {
    return repository.watchPackage(packageId);
  }
}
