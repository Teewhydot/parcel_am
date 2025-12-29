import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/dashboard_screen.dart';
import '../screens/browse_requests_screen.dart';
import '../screens/payment_screen.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key, required this.currentIndex});
  
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Details',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            activeIcon: Icon(Icons.payment),
            label: 'Payment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Browse',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Details - could be account details or help
        break;
      case 1:
        // Payment - go to payment screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PaymentScreen()),
        );
        break;
      case 2:
        // Tracking - could show recent tracking or tracking search
        break;
      case 3:
        // Dashboard
        if (currentIndex != 3) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
        break;
      case 4:
        // Browse
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const BrowseRequestsScreen()),
        );
        break;
    }
  }
}