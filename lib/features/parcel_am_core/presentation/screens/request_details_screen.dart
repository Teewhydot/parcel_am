import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../../../parcel_am_core/domain/entities/parcel_entity.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  bool _isAccepting = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    // Use provided ParcelBloc instead of creating new one
    context.read<ParcelBloc>().add(ParcelLoadRequested(widget.requestId));
  }

  void _showCancelConfirmation(ParcelEntity parcel) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: AppText.titleMedium('Cancel Request'),
          content: AppText.bodyMedium(
            'Are you sure you want to cancel this request? The held amount will be returned to your available balance.',
          ),
          actions: [
            AppButton.text(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: AppText.labelMedium('No, Keep It'),
            ),
            AppButton.primary(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _cancelParcel(parcel);
              },
              child: AppText.labelMedium('Yes, Cancel', color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  void _cancelParcel(ParcelEntity parcel) {
    setState(() {
      _isCancelling = true;
    });

    final totalAmount = (parcel.price ?? 0.0) + 150.0; // price + service fee
    context.read<ParcelBloc>().add(
      ParcelCancelRequested(
        parcelId: parcel.id,
        userId: parcel.sender.userId,
        amount: totalAmount,
      ),
    );
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
        title: AppText.titleLarge('Request Details'),
      ),
      body: BlocConsumer<ParcelBloc, BaseState<ParcelData>>(
        listener: (context, state) {
          // Handle accept result
          if (state is LoadedState<ParcelData> && _isAccepting) {
            setState(() {
              _isAccepting = false;
            });
            context.showSnackbar(
              message: 'Request accepted successfully!',
              color: AppColors.success,
            );
            sl<NavigationService>().goBack();
          } else if (state is AsyncErrorState<ParcelData> && _isAccepting) {
            setState(() {
              _isAccepting = false;
            });
            context.showSnackbar(
              message: state.errorMessage,
              color: AppColors.error,
            );
          }

          // Handle cancel result
          if (state is LoadedState<ParcelData> && _isCancelling) {
            setState(() {
              _isCancelling = false;
            });
            context.showSnackbar(
              message: 'Request cancelled. Balance returned.',
              color: AppColors.success,
            );
            sl<NavigationService>().goBack();
          } else if (state is AsyncErrorState<ParcelData> && _isCancelling) {
            setState(() {
              _isCancelling = false;
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
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  const AppText(
                    'Failed to load request details',
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.w600,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  AppText.bodyMedium(
                    state.errorMessage,
                    textAlign: TextAlign.center,
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xxl),
                  AppButton.primary(
                    onPressed: () {
                      context.read<ParcelBloc>().add(ParcelLoadRequested(widget.requestId));
                    },
                    child: AppText.bodyMedium('Retry', color: AppColors.white),
                  ),
                ],
              ),
            );
          }

          // Show loaded data
          if (state is LoadedState<ParcelData>) {
            final parcel = state.data?.currentParcel;
            if (parcel == null) {
              return Center(child: AppText.bodyMedium('Parcel not found'));
            }
            return _buildParcelDetails(parcel);
          }

          // Fallback for any other state
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocManager<ParcelBloc, BaseState<ParcelData>>(
        bloc: context.read<ParcelBloc>(),
        builder: (context, state) {
          final parcel = state.data?.currentParcel;
          if (parcel == null) {
            return const SizedBox.shrink();
          }

          // Get current user to check if they are the sender
          final authState = context.read<AuthBloc>().state;
          final currentUserId = (authState is DataState<AuthData>)
              ? authState.data?.user?.uid
              : null;
          final isCreator = currentUserId == parcel.sender.userId;

          // Creator sees Cancel button (if parcel can be cancelled)
          if (isCreator) {
            if (!parcel.status.canBeCancelled) {
              return const SizedBox.shrink();
            }
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppButton.outline(
                fullWidth: true,
                loading: _isCancelling,
                onPressed: _isCancelling ? null : () => _showCancelConfirmation(parcel),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    AppText.bodyMedium('Cancel Request', color: AppColors.error),
                  ],
                ),
              ),
            );
          }

          // Non-creators see Accept button (only for created status)
          // Hide button if user is the creator or if parcel is not in created status
          if (parcel.status != ParcelStatus.created || isCreator) {
            return const SizedBox.shrink();
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppButton.primary(
              fullWidth: true,
              loading: _isAccepting,
              requiresKyc: true,
              onPressed: () {
                _acceptRequest(parcel);
              },
              child: AppText.bodyMedium('Accept Request', color: AppColors.white),
            ),
          );
        },
        child: Container(),
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
                  const Icon(Icons.warning, color: AppColors.white),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodyMedium(
                      'Urgent delivery needed by $deliveryText',
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
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
                        borderRadius: AppRadius.lg,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            parcel.category ?? 'Package',
                            variant: TextVariant.titleLarge,
                            fontSize: AppFontSize.xxl,
                            fontWeight: FontWeight.bold,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xs),
                          AppText.headlineSmall(
                            '₦${(parcel.price ?? 0.0).toStringAsFixed(0)}',
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xs),
                          AppText.bodySmall(
                            (parcel.escrowId != null && parcel.escrowId!.isNotEmpty)
                                ? 'Payment via escrow'
                                : 'Direct payment',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Package Description
                AppText.bodyLarge(
                  parcel.description ?? 'No description provided',
                  height: 1.5,
                ),

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Sender Info
                if (parcel.sender.name.isNotEmpty) ...[
                  AppText.bodyLarge(
                    'Sender',
                    fontWeight: FontWeight.bold,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20, color: AppColors.primary),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      AppText.bodyMedium(
                        parcel.sender.name,
                      ),
                    ],
                  ),
                  if (parcel.sender.phoneNumber.isNotEmpty) ...[
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20, color: AppColors.primary),
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        AppText.bodyMedium(
                          parcel.sender.phoneNumber,
                        ),
                      ],
                    ),
                  ],
                  AppSpacing.verticalSpacing(SpacingSize.xxl),
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
                          child: const Icon(Icons.circle, color: AppColors.white, size: 8),
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
                          child: const Icon(Icons.flag, color: AppColors.white, size: 16),
                        ),
                      ],
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodySmall(
                            'From',
                            color: AppColors.onSurfaceVariant,
                          ),
                          AppText.bodyLarge(
                            parcel.route.origin,
                            fontWeight: FontWeight.w600,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.xxl),
                          AppText.bodySmall(
                            'To',
                            color: AppColors.onSurfaceVariant,
                          ),
                          AppText.bodyLarge(
                            parcel.route.destination,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Package Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard('Weight', '${parcel.weight ?? 0.0}kg'),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: _buildDetailCard(
                        'Dimensions',
                        parcel.dimensions ?? 'Not specified',
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacing(SpacingSize.lg),

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

                AppSpacing.verticalSpacing(SpacingSize.xxl),

                // Receiver Info
                AppText.bodyLarge(
                  'Receiver',
                  fontWeight: FontWeight.bold,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: AppColors.secondary),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      parcel.receiver.name,
                    ),
                  ],
                ),
                if (parcel.receiver.phoneNumber.isNotEmpty) ...[
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: AppColors.secondary),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      AppText.bodyMedium(
                        parcel.receiver.phoneNumber,
                      ),
                    ],
                  ),
                ],
                if (parcel.receiver.address.isNotEmpty) ...[
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 20, color: AppColors.secondary),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      Expanded(
                        child: AppText.bodyMedium(
                          parcel.receiver.address,
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
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodySmall(
            label,
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodyMedium(
            value,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
