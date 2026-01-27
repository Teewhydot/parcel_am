import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/services/battery_optimization_service.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../injection_container.dart';
import '../../../kyc/presentation/widgets/kyc_status_widgets.dart';
import '../widgets/user_stats_grid.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_event.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_data.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/active_packages/active_packages_cubit.dart';
import '../../domain/entities/package_entity.dart';
import 'package:parcel_am/features/chat/services/presence_service.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import '../widgets/dashboard/header_section.dart';
import '../widgets/dashboard/quick_actions_row.dart';
import '../widgets/dashboard/recent_activity_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PresenceService? _presenceService;
  ActivePackagesCubit get _activePackagesBloc =>
      context.read<ActivePackagesCubit>();
  DashboardBloc get _dashboardBloc => context.read<DashboardBloc>();
  String? _lastActivePackagesUserId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializePresence();
    _checkBatteryOptimization();
  }

  void _checkBatteryOptimization() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        BatteryOptimizationService.checkAndPromptOptimization(context);
      }
    });
  }

  @override
  void dispose() {
    _presenceService?.dispose();
    super.dispose();
  }

  void _initializePresence() {
    final userId = context.currentUserId ?? '';
    if (userId.isNotEmpty) {
      final presenceService = sl<PresenceService>();
      presenceService.initialize();
      _presenceService = presenceService;
    }
  }

  void _loadInitialData() {
    final userId = _resolveCurrentUserId();
    _requestDataForUser(userId);
  }

  void _requestDataForUser(String userId, {bool force = false}) {
    if (userId.isEmpty) return;

    if (force || _lastActivePackagesUserId != userId) {
      _lastActivePackagesUserId = userId;
      _activePackagesBloc.loadActivePackages(userId);
    }

    if (force) {
      _dashboardBloc.add(DashboardRefreshRequested(userId));
    }
  }

  String _resolveCurrentUserId() {
    return context.currentUserId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthCubit, BaseState<AuthData>>(
      listener: (context, authState) {
        _requestDataForUser(context.currentUserId ?? '');
      },
      bloc: context.read<AuthCubit>(),
      child: AppScaffold(
        hasGradientBackground: false,
        body: RefreshIndicator(
          onRefresh: () async {
            final userId = _resolveCurrentUserId();
            _requestDataForUser(userId, force: true);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: AppContainer(
              padding: AppSpacing.paddingXL,
              child: Column(
                children: [
                  const HeaderSection(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KycStatusBanner(),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      AppText.titleLarge(
                        'Quick Actions',
                        fontWeight: FontWeight.bold,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      const QuickActionsRow(),
                      AppSpacing.verticalSpacing(SpacingSize.xxl),
                      AppText.titleLarge(
                        'Your Stats',
                        fontWeight: FontWeight.bold,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      const UserStatsGrid(),
                      AppSpacing.verticalSpacing(SpacingSize.xxl),
                      BlocManager<ActivePackagesCubit,
                          BaseState<List<PackageEntity>>>(
                        bloc: context.read<ActivePackagesCubit>(),
                        showLoadingIndicator: false,
                        child: const SizedBox.shrink(),
                        builder: (context, state) {
                          if (state.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state.isError) {
                            return Center(
                              child: AppText.bodyMedium(
                                'Error: ${state.errorMessage ?? "Unknown error"}',
                              ),
                            );
                          }
                          if (state.hasData && state.data != null) {
                            return RecentActivitySection(
                              activePackages: state.data!,
                            );
                          }
                          return const RecentActivitySection(
                            activePackages: [],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
