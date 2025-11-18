import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/widgets/floating_bottom_nav_bar.dart';
import 'package:parcel_am/features/travellink/presentation/screens/dashboard_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/browse_requests_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/tracking_screen.dart';
import 'package:parcel_am/features/chat/presentation/screens/chats_list_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/wallet_screen.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';

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
    FloatingNavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Wallet',
    ),
  ];

  // Build screens for each tab based on current user
  List<Widget> _buildScreens(String userId) {
    return [
      const DashboardScreen(),
      const BrowseRequestsScreen(),
      const TrackingScreen(),
      ChatsListScreen(currentUserId: userId),
      WalletScreen(userId: userId),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Tap same tab - could scroll to top or refresh in future
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    // Double-tap back button to exit
    final now = DateTime.now();
    const backPressDuration = Duration(seconds: 2);

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > backPressDuration) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, authState) {
        // Get current user ID from auth state
        final userId = authState.data?.user?.uid;

        // If user is not authenticated, show error
        if (userId == null) {
          return const Scaffold(
            body: Center(
              child: Text('User not authenticated'),
            ),
          );
        }

        return WillPopScope(
          onWillPop: _onWillPop,
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
        );
      },
    );
  }
}
