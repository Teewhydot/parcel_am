import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../entities/dashboard_metrics_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardMetricsUseCase {
  GetDashboardMetricsUseCase([DashboardRepository? repository])
      : repository = repository ?? DashboardRepositoryImpl();

  final DashboardRepository repository;

  Future<Either<Failure, DashboardMetrics>> call(String userId) {
    return repository.getDashboardMetrics(userId);
  }
}
