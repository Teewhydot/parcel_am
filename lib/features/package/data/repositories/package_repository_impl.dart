import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/package_entity.dart';
import '../../domain/repositories/package_repository.dart';
import '../datasources/package_remote_data_source.dart';
import '../models/package_model.dart';

class PackageRepositoryImpl implements PackageRepository {
  final remoteDataSource = PackageRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
  final NetworkInfo networkInfo = _NetworkInfoImpl();

  @override
  Stream<Either<Failure, PackageEntity>> watchPackage(String packageId) {
    return ErrorHandler.handleStream(
      () => remoteDataSource.getPackageStream(packageId).map((packageMap) {
        final packageModel = PackageModel.fromMap(packageMap);
        return packageModel.toEntity();
      }),
      operationName: 'watchPackage',
    );
  }

  @override
  Stream<Either<Failure, List<PackageEntity>>> watchActivePackages(String userId) {
    return ErrorHandler.handleStream(
      () => remoteDataSource.getActivePackagesStream(userId).map((packageMaps) {
        return packageMaps
            .map((map) => PackageModel.fromMap(map).toEntity())
            .toList();
      }),
      operationName: 'watchActivePackages',
    );
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


class _NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected => InternetConnectionChecker.instance.hasConnection;
}
