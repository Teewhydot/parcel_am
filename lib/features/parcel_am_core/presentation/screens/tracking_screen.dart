import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/package_entity.dart';
import '../bloc/package/package_bloc.dart';
import '../bloc/package/package_event.dart';
import '../bloc/package/package_state.dart';
import '../bloc/tracking/tracking_cubit.dart';
import '../widgets/tracking/escrow_status_banner.dart';
import '../widgets/tracking/map_tab.dart';
import '../widgets/tracking/timeline_tab.dart';
import '../widgets/tracking/details_tab.dart';
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
                          EscrowStatusBanner(package: package),
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
                                MapTab(
                                  package: package,
                                  trackingCubit: _trackingCubit,
                                  onStartTracking: _startTracking,
                                ),
                                TimelineTab(package: package),
                                DetailsTab(
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
