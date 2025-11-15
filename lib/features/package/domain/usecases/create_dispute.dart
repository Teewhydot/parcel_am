import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/package_repository_impl.dart';

class CreateDispute {
  final repository = PackageRepositoryImpl();

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
