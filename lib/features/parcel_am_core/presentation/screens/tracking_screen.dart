import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/package_entity.dart';
import '../bloc/package/package_bloc.dart';
import '../bloc/package/package_event.dart';
import '../bloc/package/package_state.dart';
import '../bloc/tracking/tracking_cubit.dart';
import '../bloc/tracking/tracking_state.dart';
import '../widgets/live_tracking_map.dart';
import '../../../../core/helpers/user_extensions.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.packageId});
  
  final String? packageId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TrackingCubit _trackingCubit;
  final TextEditingController _confirmationCodeController = TextEditingController();
  final TextEditingController _disputeReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _trackingCubit = TrackingCubit();

    // Load package data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.packageId != null && widget.packageId!.isNotEmpty) {
        context.read<PackageBloc>().add(PackageStreamStarted(widget.packageId!));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confirmationCodeController.dispose();
    _disputeReasonController.dispose();
    _trackingCubit.close();
    super.dispose();
  }

  void _startTracking(PackageEntity package) {
    final currentUserId = context.currentUserId;
    if (currentUserId == null) return;

    _trackingCubit.startTracking(
      parcelId: package.id,
      currentUserId: currentUserId,
      package: package,
    );
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

  @override
  Widget build(BuildContext context) {
    return BlocManager<PackageBloc, BaseState<PackageData>>(
      bloc: context.read<PackageBloc>(),
      showLoadingIndicator: false,
      listener: (context, state) {
        final data = state.data;
        if (data?.escrowMessage != null) {
          context.showSnackbar(
            message: data!.escrowMessage!,
            color: data.escrowReleaseStatus == EscrowReleaseStatus.released
                ? AppColors.success
                : data.escrowReleaseStatus == EscrowReleaseStatus.failed
                    ? AppColors.error
                    : AppColors.primary,
          );
        }
      },
      child: const SizedBox.shrink(),
      builder: (context, state) {
        final package = state.data?.package;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => sl<NavigationService>().goBack(),
            ),
            title: package != null
                ? Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.lg,
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
                              'Package #${package.id.substring(0, 8)}',
                            ),
                            AppText.bodySmall(
                              _getStatusText(package.status),
                              color: _getStatusColor(package.status),
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
                onPressed: () => _sharePackageDetails(package),
              ),
            ],
          ),
          body: Container(
            decoration: package == null
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  )
                : null,
            child: state.isLoading && package == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.white))
                : package != null
                    ? Column(
                        children: [
                          _EscrowStatusBannerWidget(package: package),
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
                                _MapTabWidget(
                                  package: package,
                                  trackingCubit: _trackingCubit,
                                  onStartTracking: _startTracking,
                                ),
                                _TimelineTabWidget(package: package),
                                _DetailsTabWidget(
                                  package: package,
                                  confirmationCodeController: _confirmationCodeController,
                                  disputeReasonController: _disputeReasonController,
                                ),
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
      case 'picked_up':
        return 'Picked Up';
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

  String _formatETA(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) return 'Overdue';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h ${difference.inMinutes % 60}m';
    return '${difference.inDays}d ${difference.inHours % 24}h';
  }
}

// --- Widget Classes ---

class _EscrowStatusBannerWidget extends StatelessWidget {
  const _EscrowStatusBannerWidget({required this.package});

  final PackageEntity package;

  @override
  Widget build(BuildContext context) {
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
      case 'released':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Escrow Released - ₦${paymentInfo.amount.toStringAsFixed(2)}';
      case 'disputed':
        statusColor = AppColors.error;
        statusIcon = Icons.warning;
        statusText = 'Escrow Disputed - Under Review';
      case 'cancelled':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.cancel;
        statusText = 'Escrow Cancelled';
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Escrow Pending';
    }

    return AppContainer(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingLG.left,
        vertical: AppSpacing.paddingSM.top,
      ),
      padding: AppSpacing.paddingMD,
      color: statusColor.withValues(alpha: 0.1),
      borderRadius: AppRadius.md,
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

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}

class _MapTabWidget extends StatelessWidget {
  const _MapTabWidget({
    required this.package,
    required this.trackingCubit,
    required this.onStartTracking,
  });

  final PackageEntity package;
  final TrackingCubit trackingCubit;
  final void Function(PackageEntity) onStartTracking;

  @override
  Widget build(BuildContext context) {
    if (!trackingCubit.isTracking) {
      onStartTracking(package);
    }

    return BlocManager<TrackingCubit, BaseState<TrackingData>>(
      bloc: trackingCubit,
      showLoadingIndicator: false,
      showResultErrorNotifications: false,
      builder: (context, state) {
        final trackingData = state.data;

        return SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              if (trackingData != null)
                LiveTrackingMap(
                  trackingData: trackingData,
                  height: 250,
                )
              else if (state.isError)
                _MapErrorWidget(message: state.errorMessage ?? 'Unable to load tracking')
              else
                const _MapLoadingWidget(),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppCard.elevated(
                child: Row(
                  children: [
                    AppContainer(
                      width: 48,
                      height: 48,
                      variant: ContainerVariant.filled,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.xl,
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
                              AppText.bodyMedium('ETA: ${_formatETA(package.estimatedArrival)}', color: AppColors.primary),
                            ],
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: AppText.bodySmall(
                                  trackingData?.address ?? package.currentLocation?.name ?? 'Waiting for location...',
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              if (trackingData != null && trackingData.isLive) ...[
                                AppText.bodySmall(trackingData.formattedDistance, color: AppColors.primary),
                              ] else
                                AppText.bodySmall('${package.progress}% complete', color: AppColors.onSurfaceVariant),
                            ],
                          ),
                          if (trackingData != null && trackingData.isLive) ...[
                            AppSpacing.verticalSpacing(SpacingSize.xs),
                            Row(
                              children: [
                                Icon(Icons.speed, size: 14, color: AppColors.onSurfaceVariant),
                                AppSpacing.horizontalSpacing(SpacingSize.xs),
                                AppText.labelSmall(trackingData.formattedSpeed, color: AppColors.onSurfaceVariant),
                                AppSpacing.horizontalSpacing(SpacingSize.md),
                                Icon(Icons.update, size: 14, color: AppColors.onSurfaceVariant),
                                AppSpacing.horizontalSpacing(SpacingSize.xs),
                                AppText.labelSmall(trackingData.lastUpdateText, color: AppColors.onSurfaceVariant),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
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

  String _formatETA(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) return 'Overdue';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h ${difference.inMinutes % 60}m';
    return '${difference.inDays}d ${difference.inHours % 24}h';
  }
}

class _MapLoadingWidget extends StatelessWidget {
  const _MapLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      height: 250,
      variant: ContainerVariant.filled,
      color: AppColors.textSecondary.withValues(alpha: 0.1),
      borderRadius: AppRadius.md,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText.bodyMedium('Loading map...', color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MapErrorWidget extends StatelessWidget {
  const _MapErrorWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      height: 250,
      variant: ContainerVariant.filled,
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: AppRadius.md,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText.bodyMedium(
              message,
              color: AppColors.error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTabWidget extends StatelessWidget {
  const _TimelineTabWidget({required this.package});

  final PackageEntity package;

  @override
  Widget build(BuildContext context) {
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
                          margin: EdgeInsets.symmetric(
                            vertical: AppSpacing.paddingXS.top / 2,
                          ),
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}

class _DetailsTabWidget extends StatelessWidget {
  const _DetailsTabWidget({
    required this.package,
    required this.confirmationCodeController,
    required this.disputeReasonController,
  });

  final PackageEntity package;
  final TextEditingController confirmationCodeController;
  final TextEditingController disputeReasonController;

  @override
  Widget build(BuildContext context) {
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
                _DetailRowWidget(label: 'Type', value: package.packageType),
                _DetailRowWidget(label: 'Weight', value: '${package.weight} kg'),
                _DetailRowWidget(label: 'Urgency', value: package.urgency),
                _DetailRowWidget(label: 'Created', value: _formatDate(package.createdAt)),
                _DetailRowWidget(label: 'Est. Arrival', value: _formatDate(package.estimatedArrival)),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          if (package.paymentInfo != null) ...[
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
                  _DetailRowWidget(label: 'Amount', value: '₦${package.paymentInfo!.amount.toStringAsFixed(2)}'),
                  _DetailRowWidget(label: 'Service Fee', value: '₦${package.paymentInfo!.serviceFee.toStringAsFixed(2)}'),
                  _DetailRowWidget(label: 'Total', value: '₦${package.paymentInfo!.totalAmount.toStringAsFixed(2)}'),
                  _DetailRowWidget(label: 'Escrow Status', value: package.paymentInfo!.escrowStatus.toUpperCase()),
                  if (package.paymentInfo!.escrowHeldAt != null)
                    _DetailRowWidget(label: 'Held Since', value: _formatDate(package.paymentInfo!.escrowHeldAt!)),
                ],
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
          ],
          if (package.status == 'delivered' && package.paymentInfo?.escrowStatus == 'held') ...[
            _DeliveryConfirmationCardWidget(
              package: package,
              confirmationCodeController: confirmationCodeController,
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
          ],
          if (package.paymentInfo?.escrowStatus == 'held') ...[
            _DisputeEscrowCardWidget(
              package: package,
              disputeReasonController: disputeReasonController,
            ),
          ],
          AppSpacing.verticalSpacing(SpacingSize.lg),
          _RouteInformationCardWidget(package: package),
        ],
      ),
    );
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

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}

class _DetailRowWidget extends StatelessWidget {
  const _DetailRowWidget({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.paddingSM.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.bodyMedium(label, color: AppColors.onSurfaceVariant),
          AppText.bodyMedium(value, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}

class _DeliveryConfirmationCardWidget extends StatelessWidget {
  const _DeliveryConfirmationCardWidget({
    required this.package,
    required this.confirmationCodeController,
  });

  static const double _loadingIndicatorSize = 20.0;

  final PackageEntity package;
  final TextEditingController confirmationCodeController;

  @override
  Widget build(BuildContext context) {
    return BlocManager<PackageBloc, BaseState<PackageData>>(
      bloc: context.read<PackageBloc>(),
      showLoadingIndicator: false,
      child: const SizedBox.shrink(),
      builder: (context, state) {
        final data = state.data;
        return AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleMedium('Delivery Confirmation'),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodySmall('Enter the confirmation code to release escrow funds.', color: AppColors.onSurfaceVariant),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput(
                controller: confirmationCodeController,
                label: 'Confirmation Code',
                prefixIcon: const Icon(Icons.verified_user),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  onPressed: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? null
                      : () {
                          if (confirmationCodeController.text.isNotEmpty) {
                            context.read<PackageBloc>().add(
                                  DeliveryConfirmationRequested(
                                    packageId: package.id,
                                    confirmationCode: confirmationCodeController.text,
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
                  child: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? const SizedBox(
                          width: _loadingIndicatorSize,
                          height: _loadingIndicatorSize,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const AppText('Confirm & Release Escrow', color: AppColors.white),
                ),
              ),
              if (data?.escrowReleaseStatus == EscrowReleaseStatus.released) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                AppContainer(
                  padding: AppSpacing.paddingMD,
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.sm,
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
    );
  }
}

class _DisputeEscrowCardWidget extends StatelessWidget {
  const _DisputeEscrowCardWidget({
    required this.package,
    required this.disputeReasonController,
  });

  static const double _loadingIndicatorSize = 20.0;

  final PackageEntity package;
  final TextEditingController disputeReasonController;

  @override
  Widget build(BuildContext context) {
    return BlocManager<PackageBloc, BaseState<PackageData>>(
      bloc: context.read<PackageBloc>(),
      showLoadingIndicator: false,
      child: const SizedBox.shrink(),
      builder: (context, state) {
        final data = state.data;
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
                controller: disputeReasonController,
                label: 'Reason for Dispute',
                hintText: 'Please explain the issue...',
                maxLines: 3,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              SizedBox(
                width: double.infinity,
                child: AppButton.outline(
                  onPressed: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? null
                      : () {
                          if (disputeReasonController.text.isNotEmpty) {
                            context.read<PackageBloc>().add(
                                  EscrowDisputeRequested(
                                    packageId: package.id,
                                    transactionId: package.paymentInfo!.transactionId,
                                    reason: disputeReasonController.text,
                                  ),
                                );
                          }
                        },
                  child: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? const SizedBox(
                          width: _loadingIndicatorSize,
                          height: _loadingIndicatorSize,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const AppText('File Dispute'),
                ),
              ),
              if (data?.escrowReleaseStatus == EscrowReleaseStatus.disputed) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                AppContainer(
                  padding: AppSpacing.paddingMD,
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: AppRadius.sm,
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: AppColors.accent),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bodySmall('Dispute filed successfully', color: AppColors.accent, fontWeight: FontWeight.bold),
                            if (data?.disputeId != null)
                              AppText.bodySmall('Dispute ID: ${data!.disputeId}', color: AppColors.onSurfaceVariant),
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
    );
  }
}

class _RouteInformationCardWidget extends StatelessWidget {
  const _RouteInformationCardWidget({required this.package});

  final PackageEntity package;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
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
    );
  }
}