import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    DashboardRemoteDataSource? remoteDataSource,
  })  : remoteDataSource = remoteDataSource ?? GetIt.instance<DashboardRemoteDataSource>();
  final DashboardRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, DashboardMetrics>> getDashboardMetrics(
    String userId,
  ) async {


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
