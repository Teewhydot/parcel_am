import 'package:equatable/equatable.dart';

class DashboardMetrics extends Equatable {
  const DashboardMetrics({
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
  /// Value between 0.0 and 1.0.
  final double successRate;
  final Duration? averageDeliveryTime;
  final String currency;

  double get successRatePercent {
    final clamped = successRate.clamp(0.0, 1.0) as num;
    return clamped.toDouble() * 100;
  }

  bool get hasAverageDeliveryTime => averageDeliveryTime != null;

  @override
  List<Object?> get props => [
        totalPackages,
        activePackages,
        deliveredPackages,
        cancelledPackages,
        packagesCarried,
        totalEarnings,
        pendingEarnings,
        successRate,
        averageDeliveryTime,
        currency,
      ];
}
