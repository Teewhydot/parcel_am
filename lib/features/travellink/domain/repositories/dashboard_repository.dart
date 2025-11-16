import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_metrics_entity.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardMetrics>> getDashboardMetrics(String userId);
}
