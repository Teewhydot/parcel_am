import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../../../parcel_am_core/domain/entities/parcel_entity.dart';
import '../bloc/auth/auth_bloc.dart';
import '../widgets/my_deliveries_tab.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({super.key});

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRouteIndex = 0;
  final List<String> _routes = ['All Routes', 'Lagos', 'Abuja', 'Port Harcourt'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);

    // Initialize available parcels stream
    context.read<ParcelBloc>().add(const ParcelWatchAvailableParcelsRequested());

    // Initialize accepted parcels stream with current userId
    final authState = context.read<AuthBloc>().state;
    final userId = authState.data?.user?.uid;
    if (userId != null) {
      context.read<ParcelBloc>().add(ParcelWatchAcceptedParcelsRequested(userId));
    }

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ParcelEntity> _filterParcels(List<ParcelEntity> parcels) {
    var filtered = parcels;

    // Apply route filter
    if (_selectedRouteIndex > 0) {
      final selectedRoute = _routes[_selectedRouteIndex];
      filtered = filtered.where((parcel) {
        final origin = parcel.route.origin.toLowerCase();
        final destination = parcel.route.destination.toLowerCase();
        final route = selectedRoute.toLowerCase();
        return origin.contains(route) || destination.contains(route);
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((parcel) {
        final origin = parcel.route.origin.toLowerCase();
        final destination = parcel.route.destination.toLowerCase();
        final description = (parcel.description ?? '').toLowerCase();
        final category = (parcel.category ?? '').toLowerCase();

        return origin.contains(_searchQuery) ||
            destination.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            category.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Requests'),
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // First tab: Available requests (existing functionality)
          _buildAvailableRequestsTab(),
          // Second tab: My Deliveries (placeholder for now)
          const MyDeliveriesTab(),
        ],
      ),
    );
  }

  /// Build the Available Requests tab with existing functionality
  Widget _buildAvailableRequestsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by route or package type...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
          ),
        ),

        // Route Filter Tabs
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _routes.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedRouteIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedRouteIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    _routes[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Requests List with BLoC
        Expanded(
          child: BlocBuilder<ParcelBloc, BaseState<ParcelData>>(
            builder: (context, state) {
              if (state is AsyncLoadingState<ParcelData> && state.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is AsyncErrorState<ParcelData>) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load requests',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ParcelBloc>().add(const ParcelWatchAvailableParcelsRequested());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final availableParcels = state.data?.availableParcels ?? [];
              final filteredParcels = _filterParcels(availableParcels);

              if (availableParcels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No requests available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new delivery requests',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (filteredParcels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No matching requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters or search',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Available Requests Count
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filteredParcels.length} request${filteredParcels.length == 1 ? '' : 's'} available',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<ParcelBloc>().add(const ParcelWatchAvailableParcelsRequested());
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      child: AnimationLimiter(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredParcels.length,
                          itemBuilder: (context, index) {
                            final parcel = filteredParcels[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildRequestCard(parcel),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(ParcelEntity parcel) {
    final deliveryDateStr = parcel.route.estimatedDeliveryDate;
    String deliveryText = 'Flexible';

    if (deliveryDateStr != null && deliveryDateStr.isNotEmpty) {
      try {
        final deliveryDate = DateTime.parse(deliveryDateStr);
        final now = DateTime.now();
        final difference = deliveryDate.difference(now);

        if (difference.inHours < 24) {
          deliveryText = 'Today ${DateFormat('h:mm a').format(deliveryDate)}';
        } else if (difference.inHours < 48) {
          deliveryText = 'Tomorrow ${DateFormat('h:mm a').format(deliveryDate)}';
        } else {
          deliveryText = DateFormat('MMM d, h:mm a').format(deliveryDate);
        }
      } catch (e) {
        deliveryText = 'Flexible';
      }
    }

    final price = '₦${(parcel.price ?? 0.0).toStringAsFixed(0)}';
    final weight = '${parcel.weight ?? 0.0}kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          sl<NavigationService>().navigateTo(
            Routes.requestDetails,
            arguments: parcel.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                parcel.category ?? 'Package',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          parcel.description ?? 'No description',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(parcel.route.origin, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 1,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.flag, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(parcel.route.destination, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoChip(Icons.scale, 'Weight', weight),
                        const SizedBox(height: 8),
                        _buildInfoChip(Icons.schedule, 'Delivery', deliveryText),
                      ],
                    ),
                  ),
                  if (parcel.sender.name.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          parcel.sender.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
