import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../widgets/verification_banner.dart';
import '../widgets/user_stats_grid.dart';
import '../widgets/wallet_balance_card.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/wallet/wallet_state.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/constants/verification_constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                            // Verification Status
                            if (authProvider.user?.verificationStatus != 'verified')
                              const VerificationBanner(),
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
                            _RecentActivitySection(),
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleLarge(
              'Recent Activity',
              fontWeight: FontWeight.bold,
            ),
            AppButton.text(
              onPressed: () {},
              child: AppText.labelMedium('View All'),
            ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            final activities = [
              {
                'title': 'Documents to Abuja',
                'subtitle': 'Lagos → Abuja',
                'status': 'In Transit',
                'statusColor': AppColors.accent,
                'icon': Icons.inventory_2_outlined,
                'hasAvatar': false,
              },
              {
                'title': 'Electronics Package',
                'subtitle': 'Package Delivered',
                'status': '₦5,200',
                'statusColor': AppColors.success,
                'hasAvatar': true,
                'avatarText': 'AK',
              },
              {
                'title': 'Medical Supplies',
                'subtitle': 'Kano → Kaduna',
                'status': 'Pending',
                'statusColor': AppColors.accent,
                'icon': Icons.medical_services_outlined,
                'hasAvatar': false,
              },
            ];
            
            final activity = activities[index];
            return _ActivityItem(
              title: activity['title'] as String,
              subtitle: activity['subtitle'] as String,
              status: activity['status'] as String,
              statusColor: activity['statusColor'] as Color,
              icon: activity['icon'] as IconData?,
              hasAvatar: activity['hasAvatar'] as bool? ?? false,
              avatarText: activity['avatarText'] as String? ?? '',
              onTap: () {
                if (index == 0) {
                  sl<NavigationService>().navigateTo(Routes.tracking, arguments: {'packageId': 'TL-2024-001'});
                }
              },
            );
          },
        ),
      ],
    );
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData? icon;
  final bool hasAvatar;
  final String avatarText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
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
    );
  }
}