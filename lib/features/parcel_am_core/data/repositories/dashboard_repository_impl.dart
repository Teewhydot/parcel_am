import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    DashboardRemoteDataSource? remoteDataSource,
  })  : remoteDataSource = remoteDataSource ?? GetIt.instance<DashboardRemoteDataSource>();
  final DashboardRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, DashboardMetrics>> getDashboardMetrics(
    String userId,
  ) {
    return ErrorHandler.handle(
      () async {
        final metrics = await remoteDataSource.fetchDashboardMetrics(userId);
        return metrics.toEntity();
      },
      operationName: 'getDashboardMetrics',
    );
  }
}
