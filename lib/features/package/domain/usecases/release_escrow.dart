import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/package_repository_impl.dart';

class ReleaseEscrow {
  final repository = PackageRepositoryImpl();

  Future<Either<Failure, void>> call({
    required String packageId,
    required String transactionId,
  }) {
    return repository.releaseEscrow(
      packageId: packageId,
      transactionId: transactionId,
    );
  }
}
