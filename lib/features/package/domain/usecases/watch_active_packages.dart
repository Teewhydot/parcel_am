import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/package_entity.dart';
import '../../data/repositories/package_repository_impl.dart';

class WatchActivePackages {
  final repository = PackageRepositoryImpl();

  Stream<Either<Failure, List<PackageEntity>>> call(String userId) {
    return repository.watchActivePackages(userId);
  }
}
