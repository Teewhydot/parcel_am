import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/services/auth/kyc_guard.dart';
import 'package:parcel_am/core/services/battery_optimization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../injection_container.dart';
import '../../../kyc/presentation/widgets/kyc_status_widgets.dart';
import '../widgets/user_stats_grid.dart';
import '../widgets/wallet_balance_card.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_event.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_data.dart';
import '../../data/constants/verification_constants.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/active_packages/active_packages_cubit.dart';
import '../../domain/entities/package_entity.dart';
import 'package:parcel_am/features/chat/services/presence_service.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PresenceService? _presenceService;
  // Blocs are now provided globally from bloc_providers.dart
  ActivePackagesCubit get _activePackagesBloc => context.read<ActivePackagesCubit>();
  DashboardBloc get _dashboardBloc => context.read<DashboardBloc>();
  String? _lastActivePackagesUserId;

  @override
  void initState() {
    super.initState();

    _loadInitialData();
    _initializePresence();
    _checkBatteryOptimization();
  }

  /// Check and prompt for battery optimization settings.
  /// This helps ensure notifications work when the app is terminated.
  void _checkBatteryOptimization() {
    // Delay to avoid disrupting initial app load experience
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        BatteryOptimizationService.checkAndPromptOptimization(context);
      }
    });
  }

  @override
  void dispose() {
    _presenceService?.dispose();
    // Blocs are managed globally by bloc_providers.dart, don't close here
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

  /// Requests data for the given userId.
  /// Set [force] to true to reload data even if the userId hasn't changed (e.g., on pull-to-refresh).
  void _requestDataForUser(String userId, {bool force = false}) {
    if (userId.isEmpty) {
      return;
    }

    if (force || _lastActivePackagesUserId != userId) {
      _lastActivePackagesUserId = userId;
      _activePackagesBloc.loadActivePackages(userId);
    }

    // Dashboard refresh is handled by NavigationShell on tab switch
    // Only force refresh on pull-to-refresh
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
                    _HeaderSection(),
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
                        _QuickActionsRow(),
                        AppSpacing.verticalSpacing(SpacingSize.xxl),
                        AppText.titleLarge(
                          'Your Stats',
                          fontWeight: FontWeight.bold,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.lg),
                        const UserStatsGrid(),
                        AppSpacing.verticalSpacing(SpacingSize.xxl),
                        BlocManager<ActivePackagesCubit, BaseState<List<PackageEntity>>>(
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
                              return _RecentActivitySection(
                                activePackages: state.data!,
                              );
                            }
                            return const _RecentActivitySection(
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

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthCubit, BaseState<AuthData>>(
      bloc: context.read<AuthCubit>(),
      showLoadingIndicator: false,
      child: const SizedBox.shrink(),
      builder: (context, state) {
        final user = context.user;
        final displayName = user.displayName;
        final userName = displayName.isNotEmpty
            ? displayName.split(' ').firstOrNull ?? 'User'
            : 'User';
        final greeting = VerificationConstants.getTimeBasedGreeting();

        return AppContainer(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyLarge(
                          '$greeting, $userName!',
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodyMedium(
                          'Ready to send or deliver today?',
                          color: AppColors.black,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.black,
                        ),
                        onPressed: () {
                          sl<NavigationService>().navigateTo(Routes.settings);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline,
                          color: AppColors.black,
                        ),
                        onPressed: () {
                          sl<NavigationService>().navigateTo(Routes.profile);
                        },
                      ),
                      _NotificationButton(),
                    ],
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              const WalletBalanceCard(),
              AppSpacing.verticalSpacing(SpacingSize.md),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.black,
          ),
          onPressed: () {
            sl<NavigationService>().navigateTo(
              Routes.notifications,
              arguments: context.currentUserId ?? '',
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: AppContainer(
            width: 8,
            height: 8,
            color: AppColors.accent,
            borderRadius: AppRadius.xs,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.filled,
      color: AppColors.white.withValues(alpha: 0.2),
      padding: AppSpacing.paddingMD,
      borderRadius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIcon.filled(
            icon: icon,
            size: IconSize.small,
            backgroundColor: color.withValues(alpha: 0.2),
            color: AppColors.white,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.labelSmall(
            title,
            color: AppColors.white.withValues(alpha: 0.8),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.titleMedium(
            value,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: KycGestureDetector(
            onTap: () =>
                sl<NavigationService>().navigateTo(Routes.createParcel),
            child: _ActionCard(
              icon: Icons.add,
              title: 'Send Package',
              subtitle: 'Create a new delivery request',
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: KycGestureDetector(
            onTap: () {
              sl<NavigationService>().navigateTo(
                Routes.wallet,
                arguments: context.currentUserId ?? '',
              );
            },
            child: _ActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: 'View your wallet',
              color: AppColors.info,
            ),
          ),
        ),
    
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.surface,
      color: color,
      height: 170,
      padding: AppSpacing.paddingSM,
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.filled(
            icon: icon,
            size: IconSize.medium,
            backgroundColor: AppColors.white.withValues(alpha: 0.3),
            color: AppColors.white,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.titleMedium(
            title,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodySmall(
            subtitle,
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<PackageEntity> activePackages;

  const _RecentActivitySection({required this.activePackages});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleLarge('Active Parcels', fontWeight: FontWeight.bold),
            AppButton.text(
              onPressed: () => sl<NavigationService>().navigateTo(Routes.browseRequests),
              child: AppText.labelMedium('View All'),
            ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        activePackages.isEmpty
            ? AppContainer(
                padding: AppSpacing.paddingXL,
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: AppColors.onSurfaceVariant,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    AppText.bodyMedium(
                      'No active parcels',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activePackages.length > 5
                    ? 5
                    : activePackages.length,
                itemBuilder: (context, index) {
                  final package = activePackages[index];
                  final escrowStatus =
                      package.paymentInfo != null &&
                          package.paymentInfo!.isEscrow
                      ? package.paymentInfo!.escrowStatus
                      : null;

                  return _ActivityItem(
                    title: 'Package #${package.id.substring(0, 8)}',
                    subtitle: '${package.origin} → ${package.destination}',
                    status: _getStatusText(package.status),
                    statusColor: _getStatusColor(package.status),
                    icon: Icons.inventory_2_outlined,
                    hasAvatar: false,
                    avatarText: '',
                    escrowStatus: escrowStatus,
                    onTap: () {
                      sl<NavigationService>().navigateTo(
                        Routes.tracking,
                        arguments: {'packageId': package.id},
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'in_transit':
      case 'out_for_delivery':
        return AppColors.accent;
      case 'pending':
      case 'accepted':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.icon,
    this.hasAvatar = false,
    this.avatarText = '',
    this.escrowStatus,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData? icon;
  final bool hasAvatar;
  final String avatarText;
  final String? escrowStatus;
  final VoidCallback? onTap;

  Color _getEscrowStatusColor(String status) {
    switch (status) {
      case 'held':
        return AppColors.accent;
      case 'released':
        return AppColors.success;
      case 'disputed':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEscrowStatusIcon(String status) {
    switch (status) {
      case 'held':
        return Icons.lock;
      case 'released':
        return Icons.check_circle;
      case 'disputed':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      margin: EdgeInsets.only(bottom: SpacingSize.md.value),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              if (!hasAvatar)
                AppIcon.filled(
                  icon: icon ?? Icons.inventory_2_outlined,
                  size: IconSize.small,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                )
              else
                AppContainer(
                  width: 40,
                  height: 40,
                  variant: ContainerVariant.surface,
                  color: AppColors.primary,
                  borderRadius: AppRadius.xl,
                  alignment: Alignment.center,
                  child: AppText.labelSmall(
                    avatarText,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              AppSpacing.horizontalSpacing(SpacingSize.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(title, fontWeight: FontWeight.w600),
                    AppText.bodySmall(
                      subtitle,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppContainer(
                variant: ContainerVariant.filled,
                color: statusColor.withValues(alpha: 0.1),
                padding: EdgeInsets.symmetric(horizontal: SpacingSize.sm.value, vertical: SpacingSize.xs.value),
                borderRadius: AppRadius.md,
                child: AppText.labelSmall(
                  status,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (escrowStatus != null) ...[
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppContainer(
              padding: EdgeInsets.symmetric(horizontal: SpacingSize.sm.value, vertical: SpacingSize.xs.value),
              color: _getEscrowStatusColor(
                escrowStatus!,
              ).withValues(alpha: 0.1),
              borderRadius: AppRadius.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEscrowStatusIcon(escrowStatus!),
                    size: 14,
                    color: _getEscrowStatusColor(escrowStatus!),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.xs),
                  AppText.labelSmall(
                    'Escrow: ${escrowStatus!.toUpperCase()}',
                    color: _getEscrowStatusColor(escrowStatus!),
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
