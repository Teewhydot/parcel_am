import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
import '../../../../injection_container.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/kyc_status_widgets.dart';
import '../widgets/user_stats_grid.dart';
import '../widgets/wallet_balance_card.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/wallet/wallet_state.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/constants/verification_constants.dart';
import '../../data/datasources/package_remote_data_source.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/chat_notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription? _packagesSubscription;
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _activePackages = [];
  final NotificationService _notificationService = NotificationService(firestore: sl());
  late final PresenceService _presenceService;
  late final ChatNotificationService _chatNotificationService;

  @override
  void initState() {
    super.initState();
    _subscribeToActivePackages();
    _subscribeToEscrowNotifications();
    _initializePresenceAndChatNotifications();
  }

  @override
  void dispose() {
    _packagesSubscription?.cancel();
    _notificationSubscription?.cancel();
    _notificationService.dispose();
    _presenceService.dispose();
    _chatNotificationService.dispose();
    super.dispose();
  }

  void _initializePresenceAndChatNotifications() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? '';
    
    if (userId.isNotEmpty) {
      _presenceService = PresenceService(firestore: sl<FirebaseFirestore>());
      _presenceService.initialize(userId);

      _chatNotificationService = ChatNotificationService(
        firestore: sl<FirebaseFirestore>(),
        notificationsPlugin: FlutterLocalNotificationsPlugin(),
      );
      _chatNotificationService.initialize(userId);
      _chatNotificationService.requestPermissions();
    }
  }

  void _subscribeToActivePackages() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? 'demo_user';
    
    final dataSource = PackageRemoteDataSourceImpl(firestore: sl());
    _packagesSubscription = dataSource.getActivePackagesStream(userId).listen((packages) {
      if (mounted) {
        setState(() {
          _activePackages = packages;
        });
      }
    });
  }

  void _subscribeToEscrowNotifications() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? 'demo_user';
    
    _notificationService.subscribeToEscrowNotifications(userId);
    _notificationSubscription = _notificationService.escrowNotifications.listen((notification) {
      if (mounted) {
        _showEscrowNotification(notification);
      }
    });
  }

  void _showEscrowNotification(EscrowNotification notification) {
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => WalletBloc()..add(const WalletLoadRequested()),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
              return AppScaffold(
              hasGradientBackground: true,
              bottomNavigationBar: const BottomNavigation(currentIndex: 3),
              body: Column(
                children: [
                  // Header Section
                  _HeaderSection(),
                  // Main Content Area
                  Expanded(
                    child: AppContainer(
                      variant: ContainerVariant.surface,
                      color: AppColors.background,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      padding: AppSpacing.paddingXL,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KYC Status Banner
                            const KycStatusBanner(),
                            AppSpacing.verticalSpacing(SpacingSize.md),
                            // Quick Actions
                            AppText.titleLarge(
                              'Quick Actions',
                              fontWeight: FontWeight.bold,
                            ),
                            AppSpacing.verticalSpacing(SpacingSize.lg),
                            _QuickActionsRow(),
                            AppSpacing.verticalSpacing(SpacingSize.xxl),
                            // User Stats
                            AppText.titleLarge(
                              'Your Stats',
                              fontWeight: FontWeight.bold,
                            ),
                            AppSpacing.verticalSpacing(SpacingSize.lg),
                            const UserStatsGrid(),
                            AppSpacing.verticalSpacing(SpacingSize.xxl),
                            _RecentActivitySection(activePackages: _activePackages),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final displayName = authProvider.user?.displayName;
        final userName = displayName != null ? displayName.split(' ').firstOrNull ?? 'User' : 'User';
        final greeting = VerificationConstants.getTimeBasedGreeting();
        
        return AppContainer(
          padding: AppSpacing.paddingXL,
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
                        AppText.headlineSmall(
                          '$greeting, $userName!',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodyLarge(
                          'Ready to send or deliver today?',
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return IconButton(
                            onPressed: themeProvider.toggleTheme,
                            icon: Icon(
                              themeProvider.isDarkMode 
                                  ? Icons.light_mode 
                                  : Icons.dark_mode,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      _ChatButton(),
                      _NotificationButton(),
                    ],
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              const WalletBalanceCard(),
              AppSpacing.verticalSpacing(SpacingSize.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_actions,
                      title: 'Active Requests',
                      value: '${authProvider.user?.packagesSent ?? 3}',
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      title: 'Completed',
                      value: '${authProvider.user?.completedDeliveries ?? 12}',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
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
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.uid ?? '';

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
          .snapshots(),
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
              icon: const Icon(Icons.chat_outlined, color: Colors.white),
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
                        color: Colors.white,
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
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
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
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add,
            title: 'Send Package',
            subtitle: 'Create a new delivery request',
            color: AppColors.primary,
            onTap: () {
              // TODO: Navigate to create package
            },
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.lg),
        Expanded(
          child: _ActionCard(
            icon: Icons.search,
            title: 'Find Requests',
            subtitle: 'Browse packages to deliver',
            color: AppColors.secondary,
            onTap: () {
              sl<NavigationService>().navigateTo(Routes.browseRequests);
            },
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
      padding: AppSpacing.paddingXL,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.filled(
            icon: icon,
            size: IconSize.medium,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            color: Colors.white,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.titleMedium(
            title,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodySmall(
            subtitle,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<Map<String, dynamic>> activePackages;

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
                  final paymentInfo = package['paymentInfo'] as Map<String, dynamic>?;
                  final escrowStatus = paymentInfo != null && paymentInfo['isEscrow'] == true
                      ? paymentInfo['escrowStatus'] ?? 'pending'
                      : null;

                  return _ActivityItem(
                    title: package['title'] ?? 'Unknown Package',
                    subtitle: '${package['origin']?['name'] ?? 'Unknown'} → ${package['destination']?['name'] ?? 'Unknown'}',
                    status: _getStatusText(package['status'] ?? ''),
                    statusColor: _getStatusColor(package['status'] ?? ''),
                    icon: Icons.inventory_2_outlined,
                    hasAvatar: false,
                    avatarText: '',
                    escrowStatus: escrowStatus,
                    onTap: () {
                      sl<NavigationService>().navigateTo(
                        Routes.tracking,
                        arguments: {'packageId': package['id']},
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