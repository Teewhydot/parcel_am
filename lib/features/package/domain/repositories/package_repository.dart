import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/package_entity.dart';

abstract class PackageRepository {
  /// Watch a single package by ID
  Stream<Either<Failure, PackageEntity>> watchPackage(String packageId);

  /// Watch all active packages for a user
  Stream<Either<Failure, List<PackageEntity>>> watchActivePackages(String userId);

  /// Release escrow payment for a package
  Future<Either<Failure, void>> releaseEscrow({
    required String packageId,
    required String transactionId,
  });

  /// Create a dispute for a package
  Future<Either<Failure, String>> createDispute({
    required String packageId,
    required String transactionId,
    required String reason,
  });

  /// Confirm delivery of a package
  Future<Either<Failure, void>> confirmDelivery({
    required String packageId,
    required String confirmationCode,
  });
}
