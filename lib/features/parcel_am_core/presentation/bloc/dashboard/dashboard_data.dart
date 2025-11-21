import 'package:equatable/equatable.dart';

import '../../../domain/entities/dashboard_metrics_entity.dart';

class DashboardData extends Equatable {
  const DashboardData({
    required this.metrics,
    required this.fetchedAt,
  });

  final DashboardMetrics metrics;
  final DateTime fetchedAt;

  double get successRatePercent => metrics.successRatePercent;
  bool get hasAverageDeliveryTime => metrics.hasAverageDeliveryTime;
  Duration? get averageDeliveryTime => metrics.averageDeliveryTime;

  DashboardData copyWith({
    DashboardMetrics? metrics,
    DateTime? fetchedAt,
  }) {
    return DashboardData(
      metrics: metrics ?? this.metrics,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  List<Object?> get props => [metrics, fetchedAt];
}
