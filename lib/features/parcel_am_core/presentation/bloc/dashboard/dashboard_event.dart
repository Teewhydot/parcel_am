import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}
