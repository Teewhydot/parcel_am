import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/package_repository.dart';

class CreateDispute {
  final PackageRepository repository;

  CreateDispute(this.repository);

  Future<Either<Failure, String>> call({
    required String packageId,
    required String transactionId,
    required String reason,
  }) {
    return repository.createDispute(
      packageId: packageId,
      transactionId: transactionId,
      reason: reason,
    );
  }
}
