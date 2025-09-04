import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/bottom_navigation.dart';
import 'request_details_screen.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({super.key});

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen> {
  int _selectedRouteIndex = 0;
  final List<String> _routes = ['All Routes', 'Lagos', 'Abuja', 'Port Harcourt'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // TODO: Show filter options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by route or package type...',
                prefixIcon: const Icon(Icons.search),
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
          
          // Available Requests Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '24 requests available on your routes',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Requests List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildRequestCard(
                  title: index == 0 ? 'Important Documents' : 'Electronics Package',
                  description: index == 0 
                    ? 'Legal documents for business meeting'
                    : 'New smartphone in original packaging',
                  from: index % 2 == 0 ? 'Lagos' : 'Port Harcourt',
                  to: index % 2 == 0 ? 'Abuja' : 'Lagos',
                  price: index == 0 ? '₦3,500' : '₦7,200',
                  weight: index == 0 ? '0.5kg' : '1.2kg',
                  delivery: index == 0 ? 'Tomorrow 2PM' : 'Dec 27',
                  isUrgent: index == 0,
                  rating: 4.8,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RequestDetailsScreen(requestId: 'REQ-${index + 1}')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 4), // Browse
    );
  }

  Widget _buildRequestCard({
    required String title,
    required String description,
    required String from,
    required String to,
    required String price,
    required String weight,
    required String delivery,
    required double rating,
    bool isUrgent = false,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
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
                      color: isUrgent ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isUrgent ? Icons.priority_high : Icons.inventory_2_outlined,
                      color: isUrgent ? AppColors.error : AppColors.primary,
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
                                title,
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
                        if (isUrgent) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Urgent',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
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
                  Text(from, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 1,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.flag, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(to, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.scale, 'Weight', weight),
                  const SizedBox(width: 16),
                  _buildInfoChip(Icons.schedule, 'Delivery', delivery),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
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