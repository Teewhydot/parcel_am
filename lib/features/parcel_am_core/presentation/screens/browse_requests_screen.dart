import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text.dart';
import '../widgets/my_deliveries_tab.dart';
import '../widgets/my_packages_tab.dart';
import '../widgets/browse_requests/available_requests_tab.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({super.key});

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Browse Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // Future enhancement: Show filter dialog
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Deliveries'),
            Tab(text: 'My Packages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AvailableRequestsTab(),
          MyDeliveriesTab(),
          MyPackagesTab(),
        ],
      ),
    );
  }
}
