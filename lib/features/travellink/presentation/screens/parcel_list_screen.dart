import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../injection_container.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../../domain/models/package_model.dart';
import '../widgets/bottom_navigation.dart';
import 'create_parcel_screen.dart';

class ParcelListScreen extends StatefulWidget {
  const ParcelListScreen({super.key});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  late ParcelBloc _parcelBloc;

  @override
  void initState() {
    super.initState();
    _parcelBloc = sl<ParcelBloc>();
    _parcelBloc.add(const ParcelListRequested());
  }

  @override
  void dispose() {
    _parcelBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _parcelBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Parcels'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _parcelBloc.add(const ParcelListRequested()),
            ),
          ],
        ),
        body: StreamBuilder<List<PackageModel>>(
          stream: _parcelBloc.parcelsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return BlocBuilder<ParcelBloc, ParcelState>(
              builder: (context, state) {
                if (state is ParcelLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ParcelError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.md),
                        Text(
                          state.message,
                          style: const TextStyle(fontSize: 16),
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.lg),
                        ElevatedButton(
                          onPressed: () =>
                              _parcelBloc.add(const ParcelListRequested()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final parcels = snapshot.data ?? [];

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
                        const Text(
                          'No parcels yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        const Text(
                          'Create your first parcel to get started',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.lg),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateParcelScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Parcel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _parcelBloc.add(const ParcelListRequested());
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
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateParcelScreen(),
              ),
            );
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
  final PackageModel parcel;

  const _ParcelCard({required this.parcel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to parcel details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: AppSpacing.paddingLG,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPackageIcon(parcel.packageType),
                      color: _getStatusColor(parcel.status),
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parcel.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${parcel.origin.name} → ${parcel.destination.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
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
                      '${parcel.weight} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.speed,
                      parcel.urgency,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.payments,
                      '₦${parcel.price.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
              if (parcel.paymentInfo != null) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getEscrowColor(parcel.paymentInfo!.escrowStatus)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getEscrowColor(parcel.paymentInfo!.escrowStatus)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getEscrowIcon(parcel.paymentInfo!.escrowStatus),
                        size: 16,
                        color: _getEscrowColor(parcel.paymentInfo!.escrowStatus),
                      ),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      Text(
                        _getEscrowText(parcel.paymentInfo!.escrowStatus),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              _getEscrowColor(parcel.paymentInfo!.escrowStatus),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₦${parcel.paymentInfo!.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              _getEscrowColor(parcel.paymentInfo!.escrowStatus),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (parcel.progress > 0) ...[
                AppSpacing.verticalSpacing(SpacingSize.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: parcel.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceVariant,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'payment_confirmed':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Pending Payment';
      case 'payment_confirmed':
        return 'Paid';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _getPackageIcon(String packageType) {
    switch (packageType) {
      case 'Documents':
        return Icons.description;
      case 'Electronics':
        return Icons.devices;
      case 'Clothing':
        return Icons.checkroom;
      case 'Food':
        return Icons.restaurant;
      case 'Fragile':
        return Icons.bubble_chart;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getEscrowColor(String status) {
    switch (status.toLowerCase()) {
      case 'held':
        return Colors.blue;
      case 'released':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getEscrowIcon(String status) {
    switch (status.toLowerCase()) {
      case 'held':
        return Icons.lock;
      case 'released':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.hourglass_bottom;
    }
  }

  String _getEscrowText(String status) {
    switch (status.toLowerCase()) {
      case 'held':
        return 'Escrow Held';
      case 'released':
        return 'Escrow Released';
      case 'cancelled':
        return 'Escrow Cancelled';
      default:
        return 'Escrow Pending';
    }
  }
}
