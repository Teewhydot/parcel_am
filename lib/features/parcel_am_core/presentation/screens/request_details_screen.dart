import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../../../parcel_am_core/domain/entities/parcel_entity.dart';
import '../../../../core/helpers/user_extensions.dart';

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    // Use provided ParcelBloc instead of creating new one
    context.read<ParcelBloc>().add(ParcelLoadRequested(widget.requestId));
  }

  Future<void> _acceptRequest(ParcelEntity parcel) async {
    // Get user from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is! DataState<AuthData> || authState.data?.user == null) {
      if (mounted) {
        context.showSnackbar(
          message: 'You must be logged in to accept requests',
          color: AppColors.error,
        );
      }
      return;
    }

    final currentUser = authState.data!.user!;

    setState(() {
      _isAccepting = true;
    });

    context.read<ParcelBloc>().add(ParcelAssignTravelerRequested(
      parcelId: parcel.id,
      travelerId: currentUser.uid,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: BlocConsumer<ParcelBloc, BaseState<ParcelData>>(
        listener: (context, state) {
          if (state is LoadedState<ParcelData> && _isAccepting) {
            setState(() {
              _isAccepting = false;
            });
            context.showSnackbar(
              message: 'Request accepted successfully!',
              color: AppColors.success,
            );
            Navigator.of(context).pop();
          } else if (state is AsyncErrorState<ParcelData> && _isAccepting) {
            setState(() {
              _isAccepting = false;
            });
            context.showSnackbar(
              message: state.errorMessage,
              color: AppColors.error,
            );
          }
        },
        builder: (context, state) {
          // Show loading only on initial load
          if (state is LoadingState<ParcelData>) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error state
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
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load request details',
                    style: TextStyle(
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
                      context.read<ParcelBloc>().add(ParcelLoadRequested(widget.requestId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show loaded data
          if (state is LoadedState<ParcelData>) {
            final parcel = state.data?.currentParcel;
            if (parcel == null) {
              return const Center(child: Text('Parcel not found'));
            }
            return _buildParcelDetails(parcel);
          }

          // Fallback for any other state
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<ParcelBloc, BaseState<ParcelData>>(
        builder: (context, state) {
          final parcel = state.data?.currentParcel;
          if (parcel == null || parcel.status != ParcelStatus.created) {
            return const SizedBox.shrink();
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _isAccepting ? null : () => _acceptRequest(parcel),
              child: _isAccepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Accept Request'),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildParcelDetails(ParcelEntity parcel) {
    final deliveryDateStr = parcel.route.estimatedDeliveryDate;
    String deliveryText = 'Flexible';
    bool isUrgent = false;

    if (deliveryDateStr != null && deliveryDateStr.isNotEmpty) {
      try {
        final deliveryDate = DateTime.parse(deliveryDateStr);
        final now = DateTime.now();
        final difference = deliveryDate.difference(now);

        isUrgent = difference.inHours < 48;

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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgent Banner
          if (isUrgent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.error,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Urgent delivery needed by $deliveryText',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parcel.category ?? 'Package',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₦${(parcel.price ?? 0.0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (parcel.escrowId != null && parcel.escrowId!.isNotEmpty)
                                ? 'Payment via escrow'
                                : 'Direct payment',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Package Description
                Text(
                  parcel.description ?? 'No description provided',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Sender Info
                if (parcel.sender.name.isNotEmpty) ...[
                  const Text(
                    'Sender',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        parcel.sender.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (parcel.sender.phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          parcel.sender.phoneNumber,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Route Info
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.circle, color: Colors.white, size: 8),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: AppColors.outline,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            parcel.route.origin,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'To',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            parcel.route.destination,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Package Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard('Weight', '${parcel.weight ?? 0.0}kg'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailCard(
                        'Dimensions',
                        parcel.dimensions ?? 'Not specified',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        'Deliver by',
                        deliveryText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Receiver Info
                const Text(
                  'Receiver',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      parcel.receiver.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (parcel.receiver.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        parcel.receiver.phoneNumber,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
                if (parcel.receiver.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 20, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parcel.receiver.address,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
