import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helpers/user_extensions.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/widgets/animated_gradient_border.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/utils/logger.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/parcel_entity.dart';
import '../bloc/parcel/parcel_cubit.dart';
import '../bloc/parcel/parcel_state.dart';
import 'status_update_action_sheet.dart';
import '../../../chat/domain/usecases/chat_usecase.dart';

/// Delivery card widget for displaying accepted parcel information.
///
/// Displays comprehensive delivery information including:
/// - Package details (category, price, route, weight, dimensions)
/// - Status indicator badge with color coding
/// - Receiver contact information for delivery coordination
/// - Sender information with chat access
/// - Delivery urgency indicator for time-sensitive deliveries
/// - Status update action button
class DeliveryCard extends StatefulWidget {
  final ParcelEntity parcel;
  final VoidCallback? onUpdateStatus;

  const DeliveryCard({super.key, required this.parcel, this.onUpdateStatus});

  @override
  State<DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<DeliveryCard> {
  bool _isHovered = false;
  bool _isChatLoading = false;

  @override
  Widget build(BuildContext context) {
    final isOngoingDelivery = widget.parcel.status.isActive;

    final cardContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: _isHovered ? 6 : 2,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          child: InkWell(
            onTap: () {
              sl<NavigationService>().navigateTo(
                Routes.requestDetails,
                arguments: widget.parcel.id,
              );
            },
            borderRadius: AppRadius.lg,
            splashColor: AppColors.primary.withValues(alpha: 0.1),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(context),
                  AppSpacing.verticalSpacing(SpacingSize.lg),

                  _buildParcelInfoSection(context),
                  AppSpacing.verticalSpacing(SpacingSize.lg),

                  _buildSenderSection(context),
                  AppSpacing.verticalSpacing(SpacingSize.md),

                  const Divider(),
                  AppSpacing.verticalSpacing(SpacingSize.md),

                  _buildReceiverSection(context),

                  if (widget.parcel.hasUrgentDelivery) ...[
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    _buildUrgencyIndicator(),
                  ],

                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  _buildUpdateStatusButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isOngoingDelivery) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AnimatedGradientBorder(
          enabled: true,
          borderWidth: 2.5,
          borderRadius: 16,
          duration: const Duration(seconds: 3),
          child: cardContent,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: cardContent,
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.md,
          ),
          child: Icon(_getCategoryIcon(), color: AppColors.primary, size: 28),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      widget.parcel.category ?? 'Package',
                      variant: TextVariant.titleMedium,
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText(
                '${widget.parcel.currency ?? '₦'}${(widget.parcel.price ?? 0.0).toStringAsFixed(0)}',
                variant: TextVariant.titleMedium,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.parcel.status.statusColor.withValues(alpha: 0.15),
          borderRadius: AppRadius.md,
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
            AppSpacing.horizontalSpacing(SpacingSize.xs),
            AppText.bodySmall(
              widget.parcel.status.displayName,
              fontWeight: FontWeight.w600,
              color: widget.parcel.status.statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelInfoSection(BuildContext context) {
    final weight = widget.parcel.weight != null
        ? '${widget.parcel.weight}kg'
        : 'N/A';
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
              child: AppText.bodyMedium(
                widget.parcel.route.origin,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              Container(width: 2, height: 16, color: AppColors.outline),
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
            Icon(Icons.flag, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: AppText.bodyMedium(
                widget.parcel.route.destination,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),

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
        if (widget.parcel.description != null &&
            widget.parcel.description!.isNotEmpty) ...[
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText(
            widget.parcel.description!,
            variant: TextVariant.bodySmall,
            fontSize: AppFontSize.md,
            color: AppColors.onSurfaceVariant,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSenderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Sender',
                  variant: TextVariant.bodySmall,
                  fontSize: AppFontSize.sm,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 2),
                AppText.bodyMedium(
                  widget.parcel.sender.name,
                  fontWeight: FontWeight.w600,
                ),
                if (widget.parcel.sender.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AppText.bodySmall(
                    widget.parcel.sender.phoneNumber,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          // Chat with sender button
          _isChatLoading
              ? Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : IconButton(
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
            AppText.bodySmall(
              'Receiver Details',
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
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
                        child: AppText.bodyMedium(
                          widget.parcel.receiver.name,
                          fontWeight: FontWeight.w500,
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
                          onTap: () => _handlePhoneCall(
                            widget.parcel.receiver.phoneNumber,
                          ),
                          child: AppText(
                            widget.parcel.receiver.phoneNumber,
                            variant: TextVariant.bodyMedium,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
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
                        child: AppText(
                          widget.parcel.receiver.address,
                          variant: TextVariant.bodySmall,
                          fontSize: AppFontSize.md,
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
          color: AppColors.pending.withValues(alpha: 0.15),
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: AppColors.pending.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: AppColors.pendingDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodySmall(
                    'Urgent Delivery',
                    fontWeight: FontWeight.w600,
                    color: AppColors.pendingDark,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    'Deliver by $formattedDate',
                    variant: TextVariant.bodySmall,
                    fontSize: AppFontSize.sm,
                    color: AppColors.pendingDark,
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

  Widget _buildUpdateStatusButton(BuildContext context) {
    final isDelivered = widget.parcel.status == ParcelStatus.delivered;
    final isAwaitingConfirmation =
        widget.parcel.status == ParcelStatus.awaitingConfirmation;
    final nextStatus = widget.parcel.status.nextDeliveryStatus;

    return BlocBuilder<ParcelCubit, BaseState<ParcelData>>(
      buildWhen: (previous, current) {
        // Only rebuild when the updating parcel ID changes
        final prevUpdating = previous.data?.updatingParcelId;
        final currUpdating = current.data?.updatingParcelId;
        return prevUpdating != currUpdating;
      },
      builder: (context, state) {
        final isUpdating = state.data?.updatingParcelId == widget.parcel.id;

        // Determine button state and text
        final bool isDisabled =
            isDelivered ||
            isAwaitingConfirmation ||
            nextStatus == null ||
            isUpdating;

        String buttonText;
        IconData buttonIcon;
        Color buttonTextColor;

        if (isUpdating) {
          buttonText = 'Updating...';
          buttonIcon = Icons.update;
          buttonTextColor = AppColors.white;
        } else if (isDelivered) {
          buttonText = 'Delivered';
          buttonIcon = Icons.check_circle;
          buttonTextColor = AppColors.successDark;
        } else if (isAwaitingConfirmation) {
          buttonText = 'Awaiting Sender Confirmation';
          buttonIcon = Icons.hourglass_empty;
          buttonTextColor = AppColors.warning;
        } else if (nextStatus != null) {
          buttonText = 'Update to ${nextStatus.displayName}';
          buttonIcon = Icons.update;
          buttonTextColor = AppColors.white;
        } else {
          buttonText = 'Update Status';
          buttonIcon = Icons.update;
          buttonTextColor = AppColors.white;
        }

        return AppButton.primary(
          onPressed: isDisabled
              ? null
              : () {
                  StatusUpdateActionSheet.show(context, widget.parcel);
                },
          fullWidth: true,
          loading: isUpdating,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isUpdating) ...[
                Icon(buttonIcon, size: 20, color: buttonTextColor),
                AppSpacing.horizontalSpacing(SpacingSize.sm),
              ],
              AppText(
                buttonText,
                variant: TextVariant.bodyMedium,
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w600,
                color: buttonTextColor,
              ),
            ],
          ),
        );
      },
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
      case ParcelStatus.awaitingConfirmation:
        return Icons.hourglass_empty;
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
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          AppSpacing.horizontalSpacing(SpacingSize.xs),
          AppText.bodySmall(
            value,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Future<void> _handleChatNavigation(BuildContext context) async {
    if (_isChatLoading) return;

    final currentUserId = context.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText.bodyMedium(
            'Please sign in to chat',
            color: AppColors.white,
          ),
        ),
      );
      return;
    }

    try {
      setState(() => _isChatLoading = true);

      final currentUserName = context.user.displayName.isNotEmpty
          ? context.user.displayName
          : 'User';
      final otherUserId = widget.parcel.sender.userId;
      final otherUserName = widget.parcel.sender.name;

      // Generate chatId using sorted user IDs for consistency
      final chatId = _generateChatId(currentUserId, otherUserId);

      // Ensure chat exists before navigation
      final chatUseCase = ChatUseCase();
      await chatUseCase.getOrCreateChat(
        chatId: chatId,
        participantIds: [currentUserId, otherUserId],
        participantNames: {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
      );

      if (!mounted) return;

      // Navigate to chat screen with required arguments
      sl<NavigationService>().navigateTo(
        Routes.chat,
        arguments: {
          'chatId': chatId,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'otherUserAvatar': null, // Avatar not available in current data model
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText.bodyMedium(
              'Failed to open chat: $e',
              color: AppColors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChatLoading = false);
      }
    }
  }

  /// Generate deterministic chatId from two user IDs
  /// Format: {sortedId1}_{sortedId2}
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> _handlePhoneCall(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      // Silently fail - phone link may not be supported on all platforms
      Logger.logError('Failed to launch phone call: $e', tag: 'DeliveryCard');
    }
  }
}

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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    _buildShimmerBox(56, 56, borderRadius: 12),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(120, 18),
                          AppSpacing.verticalSpacing(SpacingSize.sm),
                          _buildShimmerBox(80, 18),
                        ],
                      ),
                    ),
                    _buildShimmerBox(80, 28, borderRadius: 12),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),

                // Route information
                _buildShimmerBox(double.infinity, 16),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                _buildShimmerBox(200, 16),
                AppSpacing.verticalSpacing(SpacingSize.md),

                // Package details chips
                Row(
                  children: [
                    _buildShimmerBox(80, 24, borderRadius: 8),
                    AppSpacing.horizontalSpacing(SpacingSize.lg),
                    _buildShimmerBox(100, 24, borderRadius: 8),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),

                // Sender section
                _buildShimmerBox(double.infinity, 60, borderRadius: 12),
                AppSpacing.verticalSpacing(SpacingSize.md),

                const Divider(),
                AppSpacing.verticalSpacing(SpacingSize.md),

                // Receiver section
                _buildShimmerBox(120, 14),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                _buildShimmerBox(double.infinity, 16),
                const SizedBox(height: 6),
                _buildShimmerBox(180, 16),
                AppSpacing.verticalSpacing(SpacingSize.lg),

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
        borderRadius: BorderRadius.circular(
          borderRadius,
        ), // Keep dynamic for skeleton
      ),
    );
  }
}
