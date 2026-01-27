import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../bloc/parcel/parcel_cubit.dart';
import '../bloc/parcel/parcel_state.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_data.dart';
import '../../../parcel_am_core/domain/entities/parcel_entity.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../widgets/request_details/accept_confirmation_sheet.dart';
import '../widgets/request_details/parcel_details_content.dart';

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
    context.read<ParcelCubit>().loadParcel(widget.requestId);
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

    final totalAmount = (parcel.price ?? 0.0) + 150.0;
    context.read<ParcelCubit>().cancelParcel(
      parcelId: parcel.id,
      userId: parcel.sender.userId,
      amount: totalAmount,
    );
  }

  void _showAcceptConfirmation(ParcelEntity parcel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => AcceptConfirmationSheet(
        parcel: parcel,
        onConfirm: () {
          Navigator.of(bottomSheetContext).pop();
          _acceptRequest(parcel);
        },
      ),
    );
  }

  Future<void> _acceptRequest(ParcelEntity parcel) async {
    final authState = context.read<AuthCubit>().state;
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

    context.read<ParcelCubit>().assignTraveler(
      parcel.id,
      currentUser.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Request Details'),
      ),
      body: BlocConsumer<ParcelCubit, BaseState<ParcelData>>(
        listener: (context, state) {
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
                      context.read<ParcelCubit>().loadParcel(widget.requestId);
                    },
                    child: AppText.bodyMedium('Retry', color: AppColors.white),
                  ),
                ],
              ),
            );
          }

          if (state is LoadedState<ParcelData>) {
            final parcel = state.data?.currentParcel;
            if (parcel == null) {
              return Center(child: AppText.bodyMedium('Parcel not found'));
            }
            return ParcelDetailsContent(parcel: parcel);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocManager<ParcelCubit, BaseState<ParcelData>>(
        bloc: context.read<ParcelCubit>(),
        builder: (context, state) {
          final parcel = state.data?.currentParcel;
          if (parcel == null) {
            return const SizedBox.shrink();
          }

          final authState = context.read<AuthCubit>().state;
          final currentUserId = (authState is DataState<AuthData>)
              ? authState.data?.user?.uid
              : null;
          final isCreator = currentUserId == parcel.sender.userId;

          if (isCreator) {
            if (!parcel.status.canBeCancelled) {
              return const SizedBox.shrink();
            }
            return Container(
              width: double.infinity,
              padding: AppSpacing.horizontalPaddingLG,
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

          if (parcel.status != ParcelStatus.created || isCreator) {
            return const SizedBox.shrink();
          }

          return Container(
            width: double.infinity,
            padding: AppSpacing.horizontalPaddingLG,
            child: AppButton.primary(
              fullWidth: true,
              loading: _isAccepting,
              requiresKyc: true,
              onPressed: () {
                _showAcceptConfirmation(parcel);
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
}
