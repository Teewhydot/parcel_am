import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/package_entity.dart';
import '../../domain/repositories/package_repository.dart';
import '../datasources/package_remote_data_source.dart';
import '../models/package_model.dart';

class PackageRepositoryImpl implements PackageRepository {
  final PackageRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PackageRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, PackageEntity>> watchPackage(String packageId) async* {
    if (!await networkInfo.isConnected) {
      yield const Left(NetworkFailure(failureMessage: 'No internet connection'));
      return;
    }

    try {
      await for (final packageMap in remoteDataSource.getPackageStream(packageId)) {
        final packageModel = PackageModel.fromMap(packageMap);
        yield Right(packageModel.toEntity());
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<PackageEntity>>> watchActivePackages(String userId) async* {
    if (!await networkInfo.isConnected) {
      yield const Left(NetworkFailure(failureMessage: 'No internet connection'));
      return;
    }

    try {
      await for (final packageMaps in remoteDataSource.getActivePackagesStream(userId)) {
        final packages = packageMaps
            .map((map) => PackageModel.fromMap(map).toEntity())
            .toList();
        yield Right(packages);
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> releaseEscrow({
    required String packageId,
    required String transactionId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.releaseEscrow(
        packageId: packageId,
        transactionId: transactionId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createDispute({
    required String packageId,
    required String transactionId,
    required String reason,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      final disputeId = await remoteDataSource.createDispute(
        packageId: packageId,
        transactionId: transactionId,
        reason: reason,
      );
      return Right(disputeId);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmDelivery({
    required String packageId,
    required String confirmationCode,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.confirmDelivery(
        packageId: packageId,
        confirmationCode: confirmationCode,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }
}
