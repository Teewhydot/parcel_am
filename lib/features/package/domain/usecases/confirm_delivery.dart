import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/package_repository.dart';

class ConfirmDelivery {
  final PackageRepository repository;

  ConfirmDelivery(this.repository);

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
