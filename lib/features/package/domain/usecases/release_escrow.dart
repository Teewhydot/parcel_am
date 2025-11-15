import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/package_repository.dart';

class ReleaseEscrow {
  final PackageRepository repository;

  ReleaseEscrow(this.repository);

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
