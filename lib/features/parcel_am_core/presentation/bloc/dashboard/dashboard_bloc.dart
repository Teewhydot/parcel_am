import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../domain/usecases/get_dashboard_metrics_usecase.dart';
import 'dashboard_data.dart';
import 'dashboard_event.dart';

class DashboardBloc extends BaseBloC<DashboardEvent, BaseState<DashboardData>> {
  DashboardBloc({
    GetDashboardMetricsUseCase? getDashboardMetricsUseCase,
  })  : _getDashboardMetricsUseCase = getDashboardMetricsUseCase ?? GetDashboardMetricsUseCase(),
        super(const InitialState<DashboardData>()) {
    on<DashboardStarted>(_onDashboardStarted);
    on<DashboardRefreshRequested>(_onDashboardRefreshRequested);
  }

  final GetDashboardMetricsUseCase _getDashboardMetricsUseCase;

  Future<void> _onDashboardStarted(
    DashboardStarted event,
    Emitter<BaseState<DashboardData>> emit,
  ) async {
    await _loadMetrics(
      userId: event.userId,
      emit: emit,
      showPrimaryLoading: true,
    );
  }

  Future<void> _onDashboardRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<BaseState<DashboardData>> emit,
  ) async {
    await _loadMetrics(
      userId: event.userId,
      emit: emit,
      showPrimaryLoading: false,
    );
  }

  Future<void> _loadMetrics({
    required String userId,
    required Emitter<BaseState<DashboardData>> emit,
    required bool showPrimaryLoading,
  }) async {
    if (userId.isEmpty) {
      emit(const ErrorState<DashboardData>(errorMessage: 'Missing user information.'));
      return;
    }

    final previousData = state.data;

    if (showPrimaryLoading || previousData == null) {
      emit(const LoadingState<DashboardData>());
    } else {
      emit(
        AsyncLoadingState<DashboardData>(
          data: previousData,
          isRefreshing: true,
        ),
      );
    }

    final result = await _getDashboardMetricsUseCase(userId);

    result.fold(
      (failure) {
        if (previousData != null) {
          emit(
            AsyncErrorState<DashboardData>(
              errorMessage: failure.failureMessage,
              data: previousData,
            ),
          );
        } else {
          emit(
            ErrorState<DashboardData>(
              errorMessage: failure.failureMessage,
            ),
          );
        }
      },
      (metrics) {
        final data = DashboardData(
          metrics: metrics,
          fetchedAt: DateTime.now(),
        );

        emit(
          LoadedState<DashboardData>(
            data: data,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }
}
