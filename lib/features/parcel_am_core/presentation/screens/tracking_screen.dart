import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/routes/routes.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/package_entity.dart';
import '../bloc/package/package_bloc.dart';
import '../bloc/package/package_event.dart';
import '../bloc/package/package_state.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../chat/domain/usecases/chat_usecase.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.packageId});
  
  final String? packageId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _confirmationCodeController = TextEditingController();
  final TextEditingController _disputeReasonController = TextEditingController();
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confirmationCodeController.dispose();
    _disputeReasonController.dispose();
    super.dispose();
  }

  void _sharePackageDetails(PackageEntity? package) {
    if (package == null) return;

    final shareText = '''
Package Tracking Details
========================
Package ID: ${package.id}
Status: ${_getStatusText(package.status)}
From: ${package.origin.name}
To: ${package.destination.name}
Carrier: ${package.carrier.name}
Progress: ${package.progress}%
ETA: ${_formatETA(package.estimatedArrival)}
''';

    Share.share(shareText, subject: 'Package #${package.id.substring(0, 8)} Tracking');
  }

  Future<void> _callCarrier(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText.bodyMedium('Could not launch phone dialer', color: AppColors.white)),
        );
      }
    }
  }

  Future<void> _messageCarrier(PackageEntity package) async {
    if (_isChatLoading) return;

    // Use clean architecture extension for user access
    final currentUserId = context.currentUserId;
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText.bodyMedium('Please sign in to chat', color: AppColors.white)),
        );
      }
      return;
    }

    setState(() => _isChatLoading = true);

    try {
      final currentUserName = context.user.displayName.isNotEmpty ? context.user.displayName : 'User';
      final otherUserId = package.carrier.id;
      final otherUserName = package.carrier.name;

      // Generate chatId using sorted user IDs for consistency
      final sortedIds = [currentUserId, otherUserId]..sort();
      final chatId = '${sortedIds[0]}_${sortedIds[1]}';

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

      sl<NavigationService>().navigateTo(
        Routes.chat,
        arguments: {
          'chatId': chatId,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'otherUserAvatar': null,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText.bodyMedium('Failed to open chat: $e', color: AppColors.white)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChatLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PackageBloc, PackageState>(
      listener: (context, state) {
        if (state.escrowMessage != null) {
          context.showSnackbar(
            message: state.escrowMessage!,
            color: state.escrowReleaseStatus == EscrowReleaseStatus.released
                ? AppColors.success
                : state.escrowReleaseStatus == EscrowReleaseStatus.failed
                    ? AppColors.error
                    : AppColors.primary,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => sl<NavigationService>().goBack(),
            ),
            title: state.package != null
                ? Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      AppSpacing.horizontalSpacing(SpacingSize.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bodyLarge(
                              'Package #${state.package!.id.substring(0, 8)}',
                            ),
                            AppText.bodySmall(
                              _getStatusText(state.package!.status),
                              color: _getStatusColor(state.package!.status),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : AppText.titleLarge('Package Tracking'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _sharePackageDetails(state.package),
              ),
            ],
          ),
          body: Container(
            decoration: state.package == null
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  )
                : null,
            child: state.isLoading && state.package == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.white))
                : state.package != null
                    ? Column(
                        children: [
                          _buildPackageHeader(state.package!),
                          _buildEscrowStatusBanner(state.package!),
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Live Map'),
                              Tab(text: 'Timeline'),
                              Tab(text: 'Details'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMapTab(state.package!),
                                _buildTimelineTab(state.package!),
                                _buildDetailsTab(state.package!, context),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.white.withValues(alpha: 0.8),
                            ),
                            AppSpacing.verticalSpacing(SpacingSize.lg),
                            AppText.titleLarge(
                              'No package data',
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            AppSpacing.verticalSpacing(SpacingSize.sm),
                            AppText.bodyMedium(
                              'Package information could not be loaded',
                              color: AppColors.white.withValues(alpha: 0.8),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildPackageHeader(PackageEntity package) {
    return AppContainer(
      padding: AppSpacing.paddingLG,
      child: AppContainer(
        padding: AppSpacing.paddingMD,
        variant: ContainerVariant.outlined,
        border: Border.all(color: AppColors.primary),
        color: AppColors.primary.withValues(alpha: 0.05),
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
                          AppText(package.title),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(package.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AppText.labelSmall(
                              _getStatusText(package.status),
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xs),
                      AppText.bodySmall(
                        '${package.origin.name} → ${package.destination.name}',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText('₦${package.price.toInt()}'),
                    AppText.bodySmall('ID: ${package.id}', color: AppColors.onSurfaceVariant),
                  ],
                ),
              ],
            ),
            if (package.status != 'delivered') ...

[
              AppSpacing.verticalSpacing(SpacingSize.sm),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.labelSmall('Progress'),
                      AppText.labelSmall('${package.progress}%'),
                    ],
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  LinearProgressIndicator(
                    value: package.progress / 100,
                    backgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowStatusBanner(PackageEntity package) {
    final paymentInfo = package.paymentInfo;
    if (paymentInfo == null || !paymentInfo.isEscrow) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (paymentInfo.escrowStatus) {
      case 'held':
        statusColor = AppColors.accent;
        statusIcon = Icons.lock;
        statusText = 'Escrow Held - ₦${paymentInfo.amount.toStringAsFixed(2)}';
        break;
      case 'released':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Escrow Released - ₦${paymentInfo.amount.toStringAsFixed(2)}';
        break;
      case 'disputed':
        statusColor = AppColors.error;
        statusIcon = Icons.warning;
        statusText = 'Escrow Disputed - Under Review';
        break;
      case 'cancelled':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.cancel;
        statusText = 'Escrow Cancelled';
        break;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Escrow Pending';
    }

    return AppContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: AppSpacing.paddingMD,
      color: statusColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(statusText, color: statusColor, fontWeight: FontWeight.bold),
                if (paymentInfo.escrowHeldAt != null)
                  AppText.bodySmall('Since ${_formatDate(paymentInfo.escrowHeldAt!)}', color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(PackageEntity package) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        children: [
          // Map Container (Placeholder)
          AppContainer(
            height: 250,
            variant: ContainerVariant.filled,
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      AppText.bodyMedium('Interactive Map View', color: AppColors.onSurfaceVariant),
                      AppText.bodySmall('Real-time package location', color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
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
                          decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                        ),
                        AppSpacing.horizontalSpacing(SpacingSize.xs),
                        AppText.labelSmall('Live', color: AppColors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppCard.elevated(
            child: Row(
              children: [
                AppContainer(
                  width: 48,
                  height: 48,
                  variant: ContainerVariant.filled,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  child: Icon(_getVehicleIcon(package.carrier.vehicleType), color: AppColors.primary),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.titleMedium('Current Location'),
                          AppText('ETA: ${_formatETA(package.estimatedArrival)}', color: AppColors.primary),
                        ],
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AppText.bodySmall(package.currentLocation?.name ?? 'Unknown', color: AppColors.onSurfaceVariant),
                          ),
                          AppText.bodySmall('${package.progress}% complete', color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppCard.elevated(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: AppText.titleMedium(package.carrier.name.split(' ').map((e) => e[0]).join(), color: AppColors.white),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.titleMedium(package.carrier.name),
                          Row(
                            children: [
                              AppButton.outline(onPressed: () => _callCarrier(package.carrier.phone), size: ButtonSize.small, child: const Icon(Icons.phone, size: 16)),
                              AppSpacing.horizontalSpacing(SpacingSize.sm),
                              AppButton.outline(onPressed: () => _messageCarrier(package), size: ButtonSize.small, child: const Icon(Icons.message, size: 16)),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xs),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: AppColors.accent),
                          AppSpacing.horizontalSpacing(SpacingSize.xs),
                          AppText.bodySmall('${package.carrier.rating}'),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          AppText.bodySmall('•'),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          AppText.bodySmall(package.carrier.vehicleNumber ?? 'N/A'),
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

  Widget _buildTimelineTab(PackageEntity package) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('Tracking Timeline'),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            ...package.trackingEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == package.trackingEvents.length - 1;
              
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
                          color: AppColors.white,
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
                  AppSpacing.horizontalSpacing(SpacingSize.md),
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
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodySmall(
                          event.description,
                          color: AppColors.onSurfaceVariant,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.onSurfaceVariant),
                            AppSpacing.horizontalSpacing(SpacingSize.xs),
                            AppText.labelSmall(
                              event.location,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        if (!isLast) AppSpacing.verticalSpacing(SpacingSize.md),
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

  Widget _buildDetailsTab(PackageEntity package, BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('Package Details'),
                AppSpacing.verticalSpacing(SpacingSize.md),
                _buildDetailRow('Type', package.packageType),
                _buildDetailRow('Weight', '${package.weight} kg'),
                _buildDetailRow('Urgency', package.urgency),
                _buildDetailRow('Created', _formatDate(package.createdAt)),
                _buildDetailRow('Est. Arrival', _formatDate(package.estimatedArrival)),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          if (package.paymentInfo != null) ...  [
            AppCard.elevated(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.titleMedium('Payment & Escrow'),
                      Icon(Icons.lock, color: _getEscrowStatusColor(package.paymentInfo!.escrowStatus), size: 20),
                    ],
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  _buildDetailRow('Transaction ID', package.paymentInfo!.transactionId),
                  _buildDetailRow('Amount', '₦${package.paymentInfo!.amount.toStringAsFixed(2)}'),
                  _buildDetailRow('Service Fee', '₦${package.paymentInfo!.serviceFee.toStringAsFixed(2)}'),
                  _buildDetailRow('Total', '₦${package.paymentInfo!.totalAmount.toStringAsFixed(2)}'),
                  _buildDetailRow('Escrow Status', package.paymentInfo!.escrowStatus.toUpperCase()),
                  if (package.paymentInfo!.escrowHeldAt != null)
                    _buildDetailRow('Held Since', _formatDate(package.paymentInfo!.escrowHeldAt!)),
                ],
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
          ],
          if (package.status == 'delivered' && package.paymentInfo?.escrowStatus == 'held') ...[
            BlocBuilder<PackageBloc, PackageState>(
              builder: (context, state) {
                return AppCard.elevated(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleMedium('Delivery Confirmation'),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      AppText.bodySmall('Enter the confirmation code to release escrow funds.', color: AppColors.onSurfaceVariant),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      AppInput(
                        controller: _confirmationCodeController,
                        label: 'Confirmation Code',
                        prefixIcon: const Icon(Icons.verified_user),
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.primary(
                          onPressed: state.escrowReleaseStatus == EscrowReleaseStatus.processing
                              ? null
                              : () {
                                  if (_confirmationCodeController.text.isNotEmpty) {
                                    context.read<PackageBloc>().add(
                                          DeliveryConfirmationRequested(
                                            packageId: package.id,
                                            confirmationCode: _confirmationCodeController.text,
                                          ),
                                        );
                                    context.read<PackageBloc>().add(
                                          EscrowReleaseRequested(
                                            packageId: package.id,
                                            transactionId: package.paymentInfo!.transactionId,
                                          ),
                                        );
                                  }
                                },
                          child: state.escrowReleaseStatus == EscrowReleaseStatus.processing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                              : const AppText('Confirm & Release Escrow', color: AppColors.white),
                        ),
                      ),
                      if (state.escrowReleaseStatus == EscrowReleaseStatus.released) ...[
                        AppSpacing.verticalSpacing(SpacingSize.md),
                        AppContainer(
                          padding: AppSpacing.paddingMD,
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success),
                              AppSpacing.horizontalSpacing(SpacingSize.sm),
                              Expanded(
                                child: AppText.bodySmall('Escrow released successfully!', color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
          ],
          if (package.paymentInfo?.escrowStatus == 'held') ...[
            BlocBuilder<PackageBloc, PackageState>(
              builder: (context, state) {
                return AppCard.elevated(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: AppColors.error, size: 20),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          AppText.titleMedium('Dispute Escrow'),
                        ],
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      AppText.bodySmall('If there\'s an issue with the delivery, you can file a dispute.', color: AppColors.onSurfaceVariant),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      AppInput.multiline(
                        controller: _disputeReasonController,
                        label: 'Reason for Dispute',
                        hintText: 'Please explain the issue...',
                        maxLines: 3,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.outline(
                          onPressed: state.escrowReleaseStatus == EscrowReleaseStatus.processing
                              ? null
                              : () {
                                  if (_disputeReasonController.text.isNotEmpty) {
                                    context.read<PackageBloc>().add(
                                          EscrowDisputeRequested(
                                            packageId: package.id,
                                            transactionId: package.paymentInfo!.transactionId,
                                            reason: _disputeReasonController.text,
                                          ),
                                        );
                                  }
                                },
                          child: state.escrowReleaseStatus == EscrowReleaseStatus.processing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const AppText('File Dispute'),
                        ),
                      ),
                      if (state.escrowReleaseStatus == EscrowReleaseStatus.disputed) ...[
                        AppSpacing.verticalSpacing(SpacingSize.md),
                        AppContainer(
                          padding: AppSpacing.paddingMD,
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: AppColors.accent),
                              AppSpacing.horizontalSpacing(SpacingSize.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText.bodySmall('Dispute filed successfully', color: AppColors.accent, fontWeight: FontWeight.bold),
                                    if (state.disputeId != null)
                                      AppText.bodySmall('Dispute ID: ${state.disputeId}', color: AppColors.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('Route Information'),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      child: const Icon(Icons.circle, size: 8, color: AppColors.white),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText('From: ${package.origin.name}', variant: TextVariant.titleSmall),
                          AppText.bodySmall(package.origin.address, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.md),
                Row(
                  children: [
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    Container(width: 2, height: 32, color: AppColors.outline),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.md),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, size: 12, color: AppColors.white),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText('To: ${package.destination.name}', variant: TextVariant.titleSmall),
                          AppText.bodySmall(package.destination.address, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('Carrier Information'),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: AppText.titleMedium(package.carrier.name.split(' ').map((e) => e[0]).join(), color: AppColors.white),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleMedium(package.carrier.name),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.accent),
                              AppSpacing.horizontalSpacing(SpacingSize.xs),
                              AppText.bodySmall('${package.carrier.rating} rating'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                Row(
                  children: [
                    Expanded(child: _buildDetailRow('Phone', package.carrier.phone)),
                    Expanded(child: _buildDetailRow('Vehicle', package.carrier.vehicleNumber ?? 'N/A')),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        onPressed: () => _callCarrier(package.carrier.phone),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone, size: 16, color: AppColors.white),
                            AppSpacing.horizontalSpacing(SpacingSize.xs),
                            AppText.labelMedium('Call Carrier', color: AppColors.white),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: AppButton.outline(
                        onPressed: () => _messageCarrier(package),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.message, size: 16),
                            AppSpacing.horizontalSpacing(SpacingSize.xs),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.bodyMedium(label, color: AppColors.onSurfaceVariant),
          AppText.bodyMedium(value, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'in_transit':
      case 'out_for_delivery':
        return AppColors.accent;
      case 'pending':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getEscrowStatusColor(String status) {
    switch (status) {
      case 'held':
        return AppColors.accent;
      case 'released':
        return AppColors.success;
      case 'disputed':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'plane':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  Color _getEventStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'current':
        return AppColors.primary;
      case 'pending':
        return AppColors.onSurfaceVariant;
      default:
        return AppColors.onSurfaceVariant;
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