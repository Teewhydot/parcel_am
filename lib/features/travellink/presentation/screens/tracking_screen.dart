import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../widgets/bottom_navigation.dart';
import '../../domain/models/package_model.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.packageId});
  
  final String? packageId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;
  bool _liveTracking = true;
  PackageModel? _selectedPackage;

  final List<PackageModel> _mockPackages = [
    PackageModel(
      id: 'TLN001',
      title: 'iPhone 15 Pro Max',
      description: 'Brand new iPhone from London to Lagos',
      status: 'in_transit',
      progress: 65,
      origin: LocationInfo(
        name: 'London, UK',
        address: 'Heathrow Airport, London',
        latitude: 51.4700,
        longitude: -0.4543,
      ),
      destination: LocationInfo(
        name: 'Lagos, Nigeria', 
        address: 'Victoria Island, Lagos',
        latitude: 6.5244,
        longitude: 3.3792,
      ),
      currentLocation: LocationInfo(
        name: 'Murtala Muhammed Airport, Lagos',
        address: 'Murtala Muhammed Airport, Lagos',
        latitude: 6.5773,
        longitude: 3.3211,
      ),
      carrier: CarrierInfo(
        id: 'C001',
        name: 'Adaora Okafor',
        phone: '+234 801 234 5678',
        rating: 4.8,
        vehicleType: 'plane',
        vehicleNumber: 'BA 083',
        isVerified: true,
      ),
      estimatedArrival: DateTime.now().add(const Duration(hours: 4)),
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      packageType: 'Electronics',
      weight: 1.0,
      price: 25000,
      urgency: 'normal',
      senderId: 'S001',
      trackingEvents: [
        TrackingEvent(
          id: '1',
          title: 'Package Delivered',
          description: 'Package successfully delivered to destination',
          timestamp: DateTime.now().add(const Duration(hours: 4)),
          location: 'Victoria Island, Lagos',
          status: 'pending',
        ),
        TrackingEvent(
          id: '2',
          title: 'Out for Delivery',
          description: 'Package is on its way to final destination',
          timestamp: DateTime.now().add(const Duration(hours: 2)),
          location: 'Lagos Mainland',
          status: 'pending',
        ),
        TrackingEvent(
          id: '3',
          title: 'Arrived in Lagos',
          description: 'Package has arrived at Lagos Airport',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          location: 'Murtala Muhammed Airport',
          status: 'current',
        ),
        TrackingEvent(
          id: '4',
          title: 'In Transit',
          description: 'Package is on flight BA 083 to Lagos',
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          location: 'London to Lagos Flight',
          status: 'completed',
        ),
        TrackingEvent(
          id: '5',
          title: 'Package Collected',
          description: 'Carrier collected package from sender',
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          location: 'Heathrow Airport, London',
          status: 'completed',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedPackage = _mockPackages.first;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return AppScaffold(
      title: 'Package Tracking',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => sl<NavigationService>().goBack(),
      ),
      actions: [
        IconButton(
          icon: _isRefreshing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: _handleRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {},
        ),
      ],
      appBarBackgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Package Selector
          AppContainer(
            padding: AppSpacing.paddingLG,
            child: Column(
              children: _mockPackages.map((pkg) => GestureDetector(
                onTap: () => setState(() => _selectedPackage = pkg),
                child: AppContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: AppSpacing.paddingMD,
                  variant: ContainerVariant.outlined,
                  border: Border.all(
                    color: _selectedPackage?.id == pkg.id 
                        ? AppColors.primary 
                        : AppColors.outline,
                  ),
                  color: _selectedPackage?.id == pkg.id 
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : null,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppText(pkg.title),
                                    AppSpacing.horizontalSM,
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(pkg.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: AppText.labelSmall(
                                        _getStatusText(pkg.status),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.verticalXS,
                                AppText.bodySmall(
                                  '${pkg.origin.name} → ${pkg.destination.name}',
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppText('₦${pkg.price.toInt()}'),
                              AppText.bodySmall(
                                'ID: ${pkg.id}',
                                color: AppColors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (pkg.status != 'delivered') ...[
                        AppSpacing.verticalSM,
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText.labelSmall('Progress'),
                                AppText.labelSmall('${pkg.progress}%'),
                              ],
                            ),
                            AppSpacing.verticalXS,
                            LinearProgressIndicator(
                              value: pkg.progress / 100,
                              backgroundColor: Colors.grey.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),

          // Tab Navigation
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Live Map'),
              Tab(text: 'Timeline'),
              Tab(text: 'Details'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildTimelineTab(),
                _buildDetailsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildMapTab() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        children: [
          // Map Container (Placeholder)
          AppContainer(
            height: 250,
            variant: ContainerVariant.filled,
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      AppSpacing.verticalSM,
                      AppText.bodyMedium(
                        'Interactive Map View',
                        color: AppColors.onSurfaceVariant,
                      ),
                      AppText.bodySmall(
                        'Real-time package location',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                
                // Live indicator
                if (_liveTracking)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: AppContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      variant: ContainerVariant.filled,
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.horizontalXS,
                          AppText.labelSmall('Live', color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                // Live tracking toggle
                Positioned(
                  top: 16,
                  right: 16,
                  child: AppButton.outline(
                    onPressed: () => setState(() => _liveTracking = !_liveTracking),
                    size: ButtonSize.small,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _liveTracking ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        AppSpacing.horizontalXS,
                        AppText.labelSmall(
                          _liveTracking ? 'Pause' : 'Resume',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.verticalLG,

          // Current Status Card
          AppCard.elevated(
            child: Row(
              children: [
                AppContainer(
                  width: 48,
                  height: 48,
                  variant: ContainerVariant.filled,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  child: Icon(
                    _getVehicleIcon(_selectedPackage?.carrier.vehicleType ?? ''),
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.titleMedium('Current Location'),
                          AppText(
                            'ETA: ${_formatETA(_selectedPackage?.estimatedArrival)}',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      AppSpacing.verticalXS,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.bodySmall(
                            _selectedPackage?.currentLocation?.name ?? 'Unknown',
                            color: AppColors.onSurfaceVariant,
                          ),
                          AppText.bodySmall(
                            '${_selectedPackage?.progress ?? 0}% complete',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.verticalLG,

          // Carrier Info
          AppCard.elevated(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: AppText.titleMedium(
                    (_selectedPackage?.carrier.name.split(' ').map((e) => e[0]).join() ?? 'AO'),
                    color: Colors.white,
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.titleMedium(_selectedPackage?.carrier.name ?? 'Unknown'),
                          Row(
                            children: [
                              AppButton.outline(
                                onPressed: () {},
                                size: ButtonSize.small,
                                child: const Icon(Icons.phone, size: 16),
                              ),
                              AppSpacing.horizontalSM,
                              AppButton.outline(
                                onPressed: () {},
                                size: ButtonSize.small,
                                child: const Icon(Icons.message, size: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.verticalXS,
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: AppColors.accent),
                          AppSpacing.horizontalXS,
                          AppText.bodySmall('${_selectedPackage?.carrier.rating ?? 0}'),
                          AppSpacing.horizontalSM,
                          AppText.bodySmall('•'),
                          AppSpacing.horizontalSM,
                          AppText.bodySmall(_selectedPackage?.carrier.vehicleNumber ?? 'N/A'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('Tracking Timeline'),
            AppSpacing.verticalLG,
            ...(_selectedPackage?.trackingEvents ?? []).asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == (_selectedPackage?.trackingEvents.length ?? 0) - 1;
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getEventStatusColor(event.status),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getEventIcon(event.title),
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: AppColors.outline,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                    ],
                  ),
                  AppSpacing.horizontalMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(event.title, variant: TextVariant.titleSmall),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppText.labelSmall(_formatTime(event.timestamp)),
                                AppText.labelSmall(
                                  _formatDate(event.timestamp),
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                        AppSpacing.verticalXS,
                        AppText.bodySmall(
                          event.description,
                          color: AppColors.onSurfaceVariant,
                        ),
                        AppSpacing.verticalXS,
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.onSurfaceVariant),
                            AppSpacing.horizontalXS,
                            AppText.labelSmall(
                              event.location,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        if (!isLast) AppSpacing.verticalMD,
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        children: [
          // Package Information
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('Package Information'),
                AppSpacing.verticalLG,
                _buildDetailRow('Package ID', _selectedPackage?.id ?? 'N/A'),
                _buildDetailRow('Cost', '₦${_selectedPackage?.price.toInt() ?? 0}'),
                _buildDetailRow('Status', _getStatusText(_selectedPackage?.status ?? '')),
                _buildDetailRow('Progress', '${_selectedPackage?.progress ?? 0}%'),
              ],
            ),
          ),

          AppSpacing.verticalLG,

          // Route Information
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('Route Information'),
                AppSpacing.verticalLG,
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.circle, size: 8, color: Colors.white),
                    ),
                    AppSpacing.horizontalMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText('From: ${_selectedPackage?.origin.name ?? 'N/A'}', variant: TextVariant.titleSmall),
                          AppText.bodySmall(
                            _selectedPackage?.origin.address ?? 'N/A',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalMD,
                Row(
                  children: [
                    AppSpacing.horizontalSM,
                    Container(width: 2, height: 32, color: AppColors.outline),
                  ],
                ),
                AppSpacing.verticalMD,
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, size: 12, color: Colors.white),
                    ),
                    AppSpacing.horizontalMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText('To: ${_selectedPackage?.destination.name ?? 'N/A'}', variant: TextVariant.titleSmall),
                          AppText.bodySmall(
                            _selectedPackage?.destination.address ?? 'N/A',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalLG,
                const Divider(),
                AppSpacing.verticalMD,
                Row(
                  children: [
                    Expanded(child: _buildDetailRow('Distance', '346 km')),
                    Expanded(child: _buildDetailRow('ETA', _formatETA(_selectedPackage?.estimatedArrival))),
                  ],
                ),
              ],
            ),
          ),

          AppSpacing.verticalLG,

          // Carrier Information
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('Carrier Information'),
                AppSpacing.verticalLG,
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: AppText.titleMedium(
                        (_selectedPackage?.carrier.name.split(' ').map((e) => e[0]).join() ?? 'AO'),
                        color: Colors.white,
                      ),
                    ),
                    AppSpacing.horizontalMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleMedium(_selectedPackage?.carrier.name ?? 'Unknown'),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.accent),
                              AppSpacing.horizontalXS,
                              AppText.bodySmall('${_selectedPackage?.carrier.rating ?? 0} rating'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalLG,
                Row(
                  children: [
                    Expanded(child: _buildDetailRow('Phone', _selectedPackage?.carrier.phone ?? 'N/A')),
                    Expanded(child: _buildDetailRow('Vehicle', _selectedPackage?.carrier.vehicleNumber ?? 'N/A')),
                  ],
                ),
                AppSpacing.verticalLG,
                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.white),
                            AppSpacing.horizontalXS,
                            AppText.labelMedium('Call Carrier', color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.horizontalMD,
                    Expanded(
                      child: AppButton.outline(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.message, size: 16),
                            AppSpacing.horizontalXS,
                            AppText.labelMedium('Message'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: AppText.bodySmall(
              label,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: AppText.bodyMedium(value),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.accent;
      case 'picked_up': return AppColors.secondary;
      case 'in_transit': return AppColors.primary;
      case 'out_for_delivery': return AppColors.accent;
      case 'delivered': return AppColors.success;
      default: return AppColors.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pending Pickup';
      case 'picked_up': return 'Picked Up';
      case 'in_transit': return 'In Transit';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      default: return 'Unknown';
    }
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'car': return Icons.directions_car;
      case 'bus': return Icons.directions_bus;
      case 'plane': return Icons.flight;
      case 'truck': return Icons.local_shipping;
      default: return Icons.directions_car;
    }
  }

  Color _getEventStatusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'current': return AppColors.primary;
      case 'pending': return AppColors.onSurfaceVariant;
      default: return AppColors.onSurfaceVariant;
    }
  }

  IconData _getEventIcon(String title) {
    if (title.contains('Delivered')) return Icons.check_circle;
    if (title.contains('Out for Delivery')) return Icons.local_shipping;
    if (title.contains('Arrived')) return Icons.flight_land;
    if (title.contains('Transit')) return Icons.flight;
    if (title.contains('Collected')) return Icons.inventory_2;
    return Icons.circle;
  }

  String _formatETA(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) return 'Overdue';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h ${difference.inMinutes % 60}m';
    return '${difference.inDays}d ${difference.inHours % 24}h';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}