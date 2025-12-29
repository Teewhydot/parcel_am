import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../../domain/entities/parcel_entity.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/delivery_confirmation_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class ParcelListScreen extends StatefulWidget {
  const ParcelListScreen({super.key});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  late ParcelBloc _parcelBloc;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _parcelBloc = ParcelBloc();

    // Get user ID from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is DataState<AuthData> && authState.data?.user != null) {
      _currentUserId = authState.data!.user!.uid;
      _parcelBloc.add(ParcelLoadUserParcels(_currentUserId!));
    }
  }

  @override
  void dispose() {
    _parcelBloc.close();
    super.dispose();
  }

  void _refreshParcels() {
    if (_currentUserId != null) {
      _parcelBloc.add(ParcelLoadUserParcels(_currentUserId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _parcelBloc,
      child: Scaffold(
        appBar: AppBar(
          title: AppText.titleLarge('My Parcels'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshParcels,
            ),
          ],
        ),
        body: BlocBuilder<ParcelBloc, BaseState<ParcelData>>(
          builder: (context, state) {
            if (state is LoadingState<ParcelData>) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ErrorState<ParcelData>) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    AppText.bodyLarge(state.errorMessage),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    AppButton.primary(
                      onPressed: _refreshParcels,
                      child: AppText.bodyMedium('Retry', color: Colors.white),
                    ),
                  ],
                ),
              );
            }

            final parcels = state.data?.userParcels ?? [];

            if (parcels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    AppText(
                      'No parcels yet',
                      variant: TextVariant.titleLarge,
                      fontSize: AppFontSize.xxl,
                      fontWeight: FontWeight.w600,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      'Create your first parcel to get started',
                      color: AppColors.onSurfaceVariant,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    AppButton.primary(
                      onPressed: () {
                        sl<NavigationService>().navigateTo(Routes.createParcel);
                      },
                      leadingIcon: const Icon(Icons.add, color: Colors.white),
                      child: AppText.bodyMedium('Create Parcel', color: Colors.white),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _refreshParcels();
              },
              child: ListView.builder(
                padding: AppSpacing.paddingLG,
                itemCount: parcels.length,
                itemBuilder: (context, index) {
                  final parcel = parcels[index];
                  return _ParcelCard(parcel: parcel);
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            sl<NavigationService>().navigateTo(Routes.createParcel);
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      ),
    );
  }
}


class _ParcelCard extends StatelessWidget {
  final ParcelEntity parcel;

  const _ParcelCard({required this.parcel});

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        // Navigate to parcel details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(parcel.status).withValues(alpha: 0.1),
                  borderRadius: AppRadius.md,
                ),
                child: Icon(
                  _getPackageIcon(parcel.status),
                  color: _getStatusColor(parcel.status),
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge(
                      parcel.description ?? 'Parcel #${parcel.id.substring(0, 8)}',
                      fontWeight: FontWeight.w600,
                    ),
                    AppText.bodyMedium(
                      '${parcel.route.origin} → ${parcel.route.destination}',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(parcel.status),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.scale,
                  parcel.weight != null ? '${parcel.weight} kg' : 'N/A',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.category,
                  parcel.category ?? 'General',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.payments,
                  parcel.price != null ? '₦${parcel.price!.toStringAsFixed(0)}' : 'TBD',
                ),
              ),
            ],
          ),
          if (parcel.escrowId != null) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(parcel.status)
                    .withValues(alpha: 0.1),
                borderRadius: AppRadius.sm,
                border: Border.all(
                  color: _getStatusColor(parcel.status)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 16,
                    color: _getStatusColor(parcel.status),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  AppText.bodySmall(
                    'Escrow Protected',
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(parcel.status),
                  ),
                  const Spacer(),
                  if (parcel.price != null)
                    AppText.bodySmall(
                      '₦${parcel.price!.toStringAsFixed(2)}',
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(parcel.status),
                    ),
                ],
              ),
            ),
          ],
          // Show delivery confirmation card when awaiting sender confirmation
          if (parcel.status == ParcelStatus.awaitingConfirmation)
            DeliveryConfirmationCard(parcel: parcel),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        AppSpacing.horizontalSpacing(SpacingSize.xs),
        Expanded(
          child: AppText.bodySmall(
            text,
            color: AppColors.onSurfaceVariant,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ParcelStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: AppText(
        status.displayName,
        variant: TextVariant.bodySmall,
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w600,
        color: _getStatusColor(status),
      ),
    );
  }

  Color _getStatusColor(ParcelStatus status) {
    return switch (status) {
      ParcelStatus.created => AppColors.pending,
      ParcelStatus.paid => AppColors.processing,
      ParcelStatus.pickedUp => AppColors.info,
      ParcelStatus.inTransit => AppColors.reversed,
      ParcelStatus.arrived => AppColors.secondary,
      ParcelStatus.awaitingConfirmation => AppColors.warning,
      ParcelStatus.delivered => AppColors.success,
      ParcelStatus.cancelled => AppColors.error,
      ParcelStatus.disputed => AppColors.warning,
    };
  }

  IconData _getPackageIcon(ParcelStatus status) {
    return switch (status) {
      ParcelStatus.created => Icons.description,
      ParcelStatus.paid => Icons.payment,
      ParcelStatus.pickedUp => Icons.shopping_bag,
      ParcelStatus.inTransit => Icons.local_shipping,
      ParcelStatus.arrived => Icons.place,
      ParcelStatus.awaitingConfirmation => Icons.hourglass_empty,
      ParcelStatus.delivered => Icons.check_circle,
      ParcelStatus.cancelled => Icons.cancel,
      ParcelStatus.disputed => Icons.warning,
    };
  }
}
