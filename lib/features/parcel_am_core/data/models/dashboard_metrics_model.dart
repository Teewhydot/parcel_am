import '../../domain/entities/dashboard_metrics_entity.dart';

class DashboardMetricsModel {
  const DashboardMetricsModel({
    required this.totalPackages,
    required this.activePackages,
    required this.deliveredPackages,
    required this.cancelledPackages,
    required this.packagesCarried,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.successRate,
    required this.currency,
    this.averageDeliveryTime,
  });

  final int totalPackages;
  final int activePackages;
  final int deliveredPackages;
  final int cancelledPackages;
  final int packagesCarried;
  final double totalEarnings;
  final double pendingEarnings;
  final double successRate;
  final Duration? averageDeliveryTime;
  final String currency;

  DashboardMetrics toEntity() {
    return DashboardMetrics(
      totalPackages: totalPackages,
      activePackages: activePackages,
      deliveredPackages: deliveredPackages,
      cancelledPackages: cancelledPackages,
      packagesCarried: packagesCarried,
      totalEarnings: totalEarnings,
      pendingEarnings: pendingEarnings,
      successRate: successRate,
      averageDeliveryTime: averageDeliveryTime,
      currency: currency,
    );
  }

  DashboardMetricsModel copyWith({
    int? totalPackages,
    int? activePackages,
    int? deliveredPackages,
    int? cancelledPackages,
    int? packagesCarried,
    double? totalEarnings,
    double? pendingEarnings,
    double? successRate,
    Duration? averageDeliveryTime,
    String? currency,
  }) {
    return DashboardMetricsModel(
      totalPackages: totalPackages ?? this.totalPackages,
      activePackages: activePackages ?? this.activePackages,
      deliveredPackages: deliveredPackages ?? this.deliveredPackages,
      cancelledPackages: cancelledPackages ?? this.cancelledPackages,
      packagesCarried: packagesCarried ?? this.packagesCarried,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingEarnings: pendingEarnings ?? this.pendingEarnings,
      successRate: successRate ?? this.successRate,
      averageDeliveryTime: averageDeliveryTime ?? this.averageDeliveryTime,
      currency: currency ?? this.currency,
    );
  }
}
