import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/package_repository_impl.dart';

class ConfirmDelivery {
  final repository = PackageRepositoryImpl();

  Future<Either<Failure, void>> call({
    required String packageId,
    required String confirmationCode,
  }) {
    return repository.confirmDelivery(
      packageId: packageId,
      confirmationCode: confirmationCode,
    );
  }
}
