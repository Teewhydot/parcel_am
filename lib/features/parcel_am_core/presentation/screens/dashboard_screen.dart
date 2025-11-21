import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../../data/constants/verification_constants.dart';
import '../../../package/presentation/bloc/active_packages_bloc.dart';
import '../../../package/domain/entities/package_entity.dart';
import '../../../../core/services/escrow_notification_service.dart' as escrow;
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/chat_notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  StreamSubscription? _notificationSubscription;

  final escrow.NotificationService _notificationService = sl<escrow.NotificationService>();
  PresenceService? _presenceService;
  ChatNotificationService? _chatNotificationService;
  late ActivePackagesBloc _activePackagesBloc;
  late DashboardBloc _dashboardBloc;
  String? _lastActivePackagesUserId;
  String? _lastDashboardUserId;

  @override
  void initState() {
    super.initState();
  
    _dashboardBloc = DashboardBloc();
    _activePackagesBloc = ActivePackagesBloc();
    _loadInitialData();
    _subscribeToEscrowNotifications();
    _initializePresenceAndChatNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationService.dispose();
    _presenceService?.dispose();
    _chatNotificationService?.dispose();
    _dashboardBloc.close();
    _activePackagesBloc.close();
    super.dispose();
  }

  void _initializePresenceAndChatNotifications() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is LoadedState<AuthData> ? authState.data?.user?.uid ?? '' : '';

    if (userId.isNotEmpty) {
      final presenceService = sl<PresenceService>();
      presenceService.initialize(userId);
      _presenceService = presenceService;

      final chatNotificationService = sl<ChatNotificationService>();
      chatNotificationService.initialize(userId);
      chatNotificationService.requestPermissions();
      _chatNotificationService = chatNotificationService;
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
      _activePackagesBloc.add(LoadActivePackages(userId));
    }

    if (force || _lastDashboardUserId != userId) {
      _lastDashboardUserId = userId;
      _dashboardBloc.add(DashboardStarted(userId));
    }
  }

  String _resolveCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is LoadedState<AuthData>) {
      return authState.data?.user?.uid ?? '';
    }
    return '';
  }

  void _subscribeToEscrowNotifications() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is LoadedState<AuthData> ? authState.data?.user?.uid ?? 'demo_user' : 'demo_user';

    _notificationService.subscribeToEscrowNotifications(userId);
    _notificationSubscription = _notificationService.escrowNotifications.listen((notification) {
      if (mounted) {
        _showEscrowNotification(notification);
      }
    });
  }

  void _showEscrowNotification(escrow.EscrowNotification notification) {
    Color backgroundColor;
    IconData icon;

    switch (notification.status) {
      case 'held':
        backgroundColor = AppColors.accent;
        icon = Icons.lock;
        break;
      case 'released':
        backgroundColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'disputed':
        backgroundColor = AppColors.error;
        icon = Icons.warning;
        break;
      case 'cancelled':
        backgroundColor = Colors.grey;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = AppColors.primary;
        icon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(notification.message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            sl<NavigationService>().navigateTo(
              Routes.tracking,
              arguments: {'packageId': notification.packageId},
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthBloc, BaseState<AuthData>>(
      
      listener: (context, authState) {
        final userId = authState is LoadedState<AuthData>
            ? authState.data?.user?.uid ?? ''
            : '';
        _requestDataForUser(userId);
      },
      bloc: context.read<AuthBloc>(),
      child: AppScaffold(
        hasGradientBackground: false,
        body: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _dashboardBloc),
            BlocProvider.value(value: _activePackagesBloc),
          ],
          child: SingleChildScrollView(
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
                      BlocBuilder<ActivePackagesBloc, BaseState<List<PackageEntity>>>(
                        builder: (context, state) {
                          if (state.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (state.isError) {
                            return Center(child: Text('Error: ${state.errorMessage ?? "Unknown error"}'));
                          }
                          if (state.hasData && state.data != null) {
                            return _RecentActivitySection(activePackages: state.data!);
                          }
                          return const _RecentActivitySection(activePackages: []);
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
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, authState) {
        final user = authState is LoadedState<AuthData> ? authState.data?.user : null;
        final displayName = user?.displayName;
        final userName = displayName != null ? displayName.split(' ').firstOrNull ?? 'User' : 'User';
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
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _ChatButton(),
                      IconButton(
                        icon: const Icon(Icons.person_outline, color: AppColors.black),
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

class _ChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, BaseState<AuthData>, String>(
      selector: (state) {
        if (state is LoadedState<AuthData>) {
          return state.data?.user?.uid ?? '';
        }
        return '';
      },
      builder: (context, userId) {
        if (userId.isEmpty) {
          return IconButton(
            icon: const Icon(Icons.chat_outlined, color: Colors.white),
            onPressed: () {
              sl<NavigationService>().navigateTo(Routes.chatsList);
            },
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: userId)
              .snapshots()
              .handleError((error) {
            print('❌ Firestore Error (Dashboard unread count): $error');
            if (error.toString().contains('index')) {
              print('🔍 INDEX REQUIRED: Create a composite index for:');
              print('   Collection: chats');
              print('   Fields: participants (Array)');
              print('   Or visit the Firebase Console to create the index automatically.');
            }
          }),
          builder: (context, snapshot) {
            int totalUnread = 0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final chatData = doc.data() as Map<String, dynamic>;
                final unreadCount =
                    (chatData['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;
                totalUnread += unreadCount as int;
              }
            }

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_outlined, color: Colors.black),
                  onPressed: () {
                    sl<NavigationService>().navigateTo(Routes.chatsList);
                  },
                ),
                if (totalUnread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          totalUnread > 9 ? '9+' : totalUnread.toString(),
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
          icon: const Icon(Icons.notifications_outlined, color: AppColors.black),
          onPressed: () {
            sl<NavigationService>().navigateTo(Routes.notifications);
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: AppContainer(
            width: 8,
            height: 8,
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(4),
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
      color: Colors.white.withValues(alpha: 0.2),
      padding: AppSpacing.paddingMD,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIcon.filled(
            icon: icon,
            size: IconSize.small,
            backgroundColor: color.withValues(alpha: 0.2),
            color: Colors.white,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.labelSmall(
            title,
            color: Colors.white.withValues(alpha: 0.8),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.titleMedium(
            value,
            color: Colors.white,
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
          child: _ActionCard(
            icon: Icons.add,
            title: 'Send Package',
            subtitle: 'Create a new delivery request',
            color: AppColors.primary,
            onTap: () {
              sl<NavigationService>().navigateTo(Routes.createParcel);
            },
          ),
        ),
        Expanded(
          child: _ActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'View your wallet',
            color: AppColors.info,
            onTap: () {
              final authState = context.read<AuthBloc>().state;
              final userId = authState is LoadedState<AuthData>
                  ? authState.data?.user?.uid ?? ''
                  : '';
              sl<NavigationService>().navigateTo(Routes.wallet, arguments: userId);
            },
          ),
        ),
        // Expanded(
        //   child: _ActionCard(
        //     icon: Icons.search,
        //     title: 'Find Requests',
        //     subtitle: 'Browse packages to deliver',
        //     color: AppColors.secondary,
        //     onTap: () {
        //       sl<NavigationService>().navigateTo(Routes.browseRequests);
        //     },
        //   ),
        // ),
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.surface,
      color: color,
      height: 170,
      padding: AppSpacing.paddingSM,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.filled(
            icon: icon,
            size: IconSize.medium,
            backgroundColor: AppColors.white.withValues(alpha: 0.3),
            color: Colors.white,
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
            AppText.titleLarge(
              'Active Parcels',
              fontWeight: FontWeight.bold,
            ),
            AppButton.text(
              onPressed: () {},
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
                    const Icon(Icons.inbox_outlined, size: 48, color: AppColors.onSurfaceVariant),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    AppText.bodyMedium('No active parcels', color: AppColors.onSurfaceVariant),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activePackages.length > 5 ? 5 : activePackages.length,
                itemBuilder: (context, index) {
                  final package = activePackages[index];
                  final escrowStatus = package.paymentInfo != null && package.paymentInfo!.isEscrow
                      ? package.paymentInfo!.escrowStatus ?? 'pending'
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
        return Colors.grey;
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
        return Colors.grey;
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
      margin: const EdgeInsets.only(bottom: 12),
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
                  borderRadius: BorderRadius.circular(20),
                  alignment: Alignment.center,
                  child: AppText.labelSmall(
                    avatarText,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              AppSpacing.horizontalSpacing(SpacingSize.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(
                      title,
                      fontWeight: FontWeight.w600,
                    ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: _getEscrowStatusColor(escrowStatus!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
