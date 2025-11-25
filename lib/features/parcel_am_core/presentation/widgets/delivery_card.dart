import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/parcel_entity.dart';
import 'status_update_action_sheet.dart';

/// Delivery card widget for displaying accepted parcel information.
///
/// Displays comprehensive delivery information including:
/// - Package details (category, price, route, weight, dimensions)
/// - Status indicator badge with color coding
/// - Receiver contact information for delivery coordination
/// - Sender information with chat access
/// - Delivery urgency indicator for time-sensitive deliveries
/// - Status update action button
///
/// Task Group 3.3: Fully implemented delivery card component.
/// Task Group 3.6: Added animations and polish (hover, tap effects, skeleton loader).
class DeliveryCard extends StatefulWidget {
  final ParcelEntity parcel;
  final VoidCallback? onUpdateStatus;

  const DeliveryCard({
    super.key,
    required this.parcel,
    this.onUpdateStatus,
  });

  @override
  State<DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<DeliveryCard> {
  // Task 3.6.2: Track hover state for elevation changes
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Task 3.6.2: Add hover and tap effects
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        // Task 3.6.2: Animate elevation change on hover
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: _isHovered ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            // Task 3.6.2: Ripple effect on tap
            onTap: () {
              // Navigate to parcel details (Task 3.3.1)
              sl<NavigationService>().navigateTo(
                Routes.requestDetails,
                arguments: widget.parcel.id,
              );
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primary.withValues(alpha: 0.1),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task 3.3.1 & 3.3.3: Header row with package icon and status badge
                  _buildHeaderSection(context),
                  const SizedBox(height: 16),

                  // Task 3.3.2: Parcel information section
                  _buildParcelInfoSection(context),
                  const SizedBox(height: 16),

                  // Task 3.3.5: Sender information section
                  _buildSenderSection(context),
                  const SizedBox(height: 12),

                  const Divider(),
                  const SizedBox(height: 12),

                  // Task 3.3.4: Receiver contact section
                  _buildReceiverSection(context),

                  // Task 3.3.6: Delivery urgency indicator
                  if (widget.parcel.hasUrgentDelivery) ...[
                    const SizedBox(height: 12),
                    _buildUrgencyIndicator(),
                  ],

                  // Task 3.3.7: Update Status button
                  const SizedBox(height: 16),
                  _buildUpdateStatusButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Task 3.3.1 & 3.3.3: Build header with package icon and status badge
  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(),
            color: AppColors.primary,
            size: 28,
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
                      widget.parcel.category ?? 'Package',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Task 3.3.3: Status indicator badge
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.parcel.currency ?? '₦'}${(widget.parcel.price ?? 0.0).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Task 3.3.3 & 3.6.2: Build status indicator badge with animation
  Widget _buildStatusBadge() {
    return TweenAnimationBuilder<double>(
      // Task 3.6.2: Animate status badge appearance
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: widget.parcel.status.statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.parcel.status.statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(),
              size: 14,
              color: widget.parcel.status.statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              widget.parcel.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.parcel.status.statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Task 3.3.2: Build parcel information section
  Widget _buildParcelInfoSection(BuildContext context) {
    final weight = widget.parcel.weight != null ? '${widget.parcel.weight}kg' : 'N/A';
    final dimensions = widget.parcel.dimensions ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route information
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.parcel.route.origin,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              Container(
                width: 2,
                height: 16,
                color: AppColors.outline,
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_downward,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.flag,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.parcel.route.destination,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Package details
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildInfoChip(Icons.scale_outlined, weight),
            _buildInfoChip(Icons.straighten_outlined, dimensions),
          ],
        ),

        // Package description (truncated if long)
        if (widget.parcel.description != null && widget.parcel.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.parcel.description!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Task 3.3.5: Build sender information section
  Widget _buildSenderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sender',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.parcel.sender.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.parcel.sender.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.parcel.sender.phoneNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Chat with sender button
          IconButton(
            onPressed: () => _handleChatNavigation(context),
            icon: Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary,
            ),
            tooltip: 'Chat with sender',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// Task 3.3.4: Build receiver contact section
  Widget _buildReceiverSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Receiver Details',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.parcel.receiver.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => _handlePhoneCall(widget.parcel.receiver.phoneNumber),
                          child: Text(
                            widget.parcel.receiver.phoneNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.parcel.receiver.address,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Task 3.3.6: Build delivery urgency indicator
  Widget _buildUrgencyIndicator() {
    final deliveryDateStr = widget.parcel.route.estimatedDeliveryDate;
    if (deliveryDateStr == null || deliveryDateStr.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final deliveryDate = DateTime.parse(deliveryDateStr);
      final formattedDate = DateFormat('MMM d, h:mm a').format(deliveryDate);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urgent Delivery',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Deliver by $formattedDate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  /// Task 3.3.7 & 3.4: Build Update Status button - now opens StatusUpdateActionSheet
  Widget _buildUpdateStatusButton(BuildContext context) {
    final isDelivered = widget.parcel.status == ParcelStatus.delivered;
    final nextStatus = widget.parcel.status.nextDeliveryStatus;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isDelivered || nextStatus == null
            ? null
            : () {
                // Task Group 3.4: Open status update action sheet
                StatusUpdateActionSheet.show(context, widget.parcel);
              },
        icon: Icon(
          isDelivered ? Icons.check_circle : Icons.update,
          size: 20,
        ),
        label: Text(
          isDelivered
              ? 'Delivered'
              : nextStatus != null
                  ? 'Update to ${nextStatus.displayName}'
                  : 'Update Status',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: isDelivered
              ? Colors.green.withValues(alpha: 0.2)
              : null,
          foregroundColor: isDelivered
              ? Colors.green.shade700
              : null,
          disabledBackgroundColor: isDelivered
              ? Colors.green.withValues(alpha: 0.2)
              : null,
          disabledForegroundColor: isDelivered
              ? Colors.green.shade700
              : null,
        ),
      ),
    );
  }

  // Helper methods

  /// Get icon based on package category
  IconData _getCategoryIcon() {
    final category = widget.parcel.category?.toLowerCase() ?? '';
    if (category.contains('document')) return Icons.description_outlined;
    if (category.contains('electronic')) return Icons.devices_outlined;
    if (category.contains('cloth')) return Icons.checkroom_outlined;
    if (category.contains('food')) return Icons.restaurant_outlined;
    if (category.contains('medication') || category.contains('medicine')) {
      return Icons.medication_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  /// Get icon based on status
  IconData _getStatusIcon() {
    switch (widget.parcel.status) {
      case ParcelStatus.paid:
        return Icons.payment;
      case ParcelStatus.pickedUp:
        return Icons.shopping_bag;
      case ParcelStatus.inTransit:
        return Icons.local_shipping;
      case ParcelStatus.arrived:
        return Icons.place;
      case ParcelStatus.delivered:
        return Icons.check_circle;
      case ParcelStatus.cancelled:
        return Icons.cancel;
      case ParcelStatus.disputed:
        return Icons.report_problem;
      default:
        return Icons.info;
    }
  }

  /// Build info chip for weight/dimensions
  Widget _buildInfoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Task 3.3.5: Handle chat navigation with sender
  /// Prepares navigation logic for chat (will be fully functional with Task Group 3.5)
  void _handleChatNavigation(BuildContext context) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to chat')),
        );
        return;
      }

      final currentUserId = currentUser.uid;
      final otherUserId = widget.parcel.sender.userId;

      // Generate chatId using sorted user IDs for consistency
      final chatId = _generateChatId(currentUserId, otherUserId);

      // Navigate to chat screen with required arguments
      sl<NavigationService>().navigateTo(
        Routes.chat,
        arguments: {
          'chatId': chatId,
          'otherUserId': otherUserId,
          'otherUserName': widget.parcel.sender.name,
          'otherUserAvatar': null, // Avatar not available in current data model
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }

  /// Generate deterministic chatId from two user IDs
  /// Format: {sortedId1}_{sortedId2}
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Task 3.3.4: Handle phone call to receiver
  /// Uses url_launcher package for phone link
  Future<void> _handlePhoneCall(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      // Silently fail - phone link may not be supported on all platforms
      debugPrint('Failed to launch phone call: $e');
    }
  }
}

/// Task 3.6.3: Skeleton loader for delivery card
/// Shows while parcels are loading to improve perceived performance
class DeliveryCardSkeleton extends StatefulWidget {
  const DeliveryCardSkeleton({super.key});

  @override
  State<DeliveryCardSkeleton> createState() => _DeliveryCardSkeletonState();
}

class _DeliveryCardSkeletonState extends State<DeliveryCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    _buildShimmerBox(56, 56, borderRadius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(120, 18),
                          const SizedBox(height: 8),
                          _buildShimmerBox(80, 18),
                        ],
                      ),
                    ),
                    _buildShimmerBox(80, 28, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 16),

                // Route information
                _buildShimmerBox(double.infinity, 16),
                const SizedBox(height: 8),
                _buildShimmerBox(200, 16),
                const SizedBox(height: 12),

                // Package details chips
                Row(
                  children: [
                    _buildShimmerBox(80, 24, borderRadius: 8),
                    const SizedBox(width: 16),
                    _buildShimmerBox(100, 24, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 16),

                // Sender section
                _buildShimmerBox(double.infinity, 60, borderRadius: 12),
                const SizedBox(height: 12),

                const Divider(),
                const SizedBox(height: 12),

                // Receiver section
                _buildShimmerBox(120, 14),
                const SizedBox(height: 8),
                _buildShimmerBox(double.infinity, 16),
                const SizedBox(height: 6),
                _buildShimmerBox(180, 16),
                const SizedBox(height: 16),

                // Update status button
                _buildShimmerBox(double.infinity, 48, borderRadius: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a shimmer box with animation
  Widget _buildShimmerBox(
    double width,
    double height, {
    double borderRadius = 4,
  }) {
    final shimmerGradient = LinearGradient(
      colors: [
        AppColors.surfaceVariant.withValues(alpha: 0.3),
        AppColors.surfaceVariant.withValues(alpha: 0.5),
        AppColors.surfaceVariant.withValues(alpha: 0.3),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment(-1.0 - _shimmerController.value * 2, 0.0),
      end: Alignment(1.0 - _shimmerController.value * 2, 0.0),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: shimmerGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
