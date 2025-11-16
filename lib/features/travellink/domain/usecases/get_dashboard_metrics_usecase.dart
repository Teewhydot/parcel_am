import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_metrics_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardMetricsUseCase {
  const GetDashboardMetricsUseCase(this.repository);

  final DashboardRepository repository;

  Future<Either<Failure, DashboardMetrics>> call(String userId) {
    return repository.getDashboardMetrics(userId);
  }
}
