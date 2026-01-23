import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:parcel_am/core/widgets/floating_bottom_nav_bar.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/dashboard_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/browse_requests_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/tracking_screen.dart';
import 'package:parcel_am/features/chat/presentation/screens/chats_list_screen.dart';
import 'package:parcel_am/features/chat/presentation/widgets/chat_notification_listener.dart';
// import 'package:parcel_am/features/seeder/presentation/screens/database_seeder_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/injection_container.dart';

class NavigationShell extends StatefulWidget {
  final int initialIndex;

  const NavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late int _currentIndex;
  DateTime? _lastBackPressed;
  String? _lastUserId;

  // DashboardBloc is now provided globally from bloc_providers.dart
  DashboardBloc get _dashboardBloc => context.read<DashboardBloc>();

  // Navigation items configuration
  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    FloatingNavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Browse',
    ),
    FloatingNavItem(
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on,
      label: 'Tracking',
    ),
    FloatingNavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    // FloatingNavItem(
    //   icon: Icons.storage_outlined,
    //   activeIcon: Icons.storage,
    //   label: 'Seeder',
    // ),
  ];

  // Build screens for each tab based on current user
  List<Widget> _buildScreens(String userId) {
    // Store userId for dashboard refresh
    _lastUserId = userId;

    // Initialize dashboard if first time
    if (_dashboardBloc.state.data == null) {
      _dashboardBloc.add(DashboardStarted(userId));
    }

    return [
      const DashboardScreen(),
      const BrowseRequestsScreen(),
      const TrackingScreen(),
      ChatsListScreen(currentUserId: userId),
      // const DatabaseSeederScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTapped(int index) {
    final wasDashboard = _currentIndex == 0;
    final isDashboard = index == 0;

    if (_currentIndex == index) {
      // Tap same tab - refresh if dashboard
      if (isDashboard && _lastUserId != null) {
        _dashboardBloc.add(DashboardRefreshRequested(_lastUserId!));
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Refresh dashboard when switching TO dashboard tab
    if (isDashboard && !wasDashboard && _lastUserId != null) {
      _dashboardBloc.add(DashboardRefreshRequested(_lastUserId!));
    }
  }

  Future<bool> _onWillPop() async {
    // Double-tap back button to exit
    final now = DateTime.now();
    const backPressDuration = Duration(seconds: 2);

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > backPressDuration) {
      _lastBackPressed = now;

      context.showSnackbar(
        message: 'Press back again to exit',
        duration: 2,
      );

      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthCubit, BaseState<AuthData>>(
      bloc: context.read<AuthCubit>(),
      showLoadingIndicator: false,
      child: const SizedBox.shrink(),
      builder: (context, authState) {
        final userId = context.currentUserId;

        // If user is not authenticated, show error
        if (userId == null) {
          return Scaffold(
            body: Center(
              child: AppText.bodyMedium('User not authenticated'),
            ),
          );
        }

        return ChatNotificationListener(
          userId: userId,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                sl<NavigationService>().goBack();
              }
            },
            child: Scaffold(
              body: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.dark,
                child: IndexedStack(
                  index: _currentIndex,
                  children: _buildScreens(userId),
                ),
              ),
              extendBody: true,
              bottomNavigationBar: FloatingBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                items: _navItems,
              ),
            ),
          ),
        );
      },
    );
  }
}
