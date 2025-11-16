import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final DashboardRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, DashboardMetrics>> getDashboardMetrics(
    String userId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NoInternetFailure(failureMessage: 'No internet connection'),
      );
    }

    try {
      final metrics = await remoteDataSource.fetchDashboardMetrics(userId);
      return Right(metrics.toEntity());
    } on ServerException {
      return const Left(
        ServerFailure(failureMessage: 'Failed to load dashboard metrics'),
      );
    } catch (error) {
      return Left(
        UnknownFailure(failureMessage: error.toString()),
      );
    }
  }
}
