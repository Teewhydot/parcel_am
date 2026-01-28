import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/constants/business_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_cubit.dart';
import '../../../parcel_am_core/presentation/bloc/wallet/wallet_data.dart';
import '../widgets/wallet_funding_success/status_icon.dart';
import '../widgets/wallet_funding_success/transaction_details_card.dart';
import '../widgets/wallet_funding_success/funding_action_buttons.dart';

class WalletFundingSuccessScreen extends StatefulWidget {
  final String transactionId;
  final String reference;
  final double amount;
  final String userId;

  const WalletFundingSuccessScreen({
    super.key,
    required this.transactionId,
    required this.reference,
    required this.amount,
    required this.userId,
  });

  @override
  State<WalletFundingSuccessScreen> createState() =>
      _WalletFundingSuccessScreenState();
}

class _WalletFundingSuccessScreenState
    extends State<WalletFundingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Payment status tracking
  String _paymentStatus = 'pending';
  bool _isLoadingStatus = true;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();

    // Start listening to payment status
    _listenToPaymentStatus();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _listenToPaymentStatus() {
    final fundingOrderId = 'F-${widget.reference}';

    _statusSubscription = FirebaseFirestore.instance
        .collection('funding_orders')
        .doc(fundingOrderId)
        .snapshots()
        .listen(
      (docSnapshot) {
        if (!mounted) return;

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            final status = data['status'] as String? ?? 'pending';
            setState(() {
              _paymentStatus = status.toLowerCase();
              _isLoadingStatus = false;
            });
          }
        } else {
          // Document doesn't exist yet, keep as pending
          setState(() {
            _isLoadingStatus = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoadingStatus = false;
        });
      },
    );
  }

  bool _isSuccessStatus() {
    return BusinessConstants.isSuccessStatus(_paymentStatus);
  }

  bool _isPendingStatus() {
    return _paymentStatus == 'pending';
  }

  bool _isFailedStatus() {
    return BusinessConstants.isFailureStatus(_paymentStatus);
  }

  String _getStatusTitle() {
    if (_isLoadingStatus) {
      return 'Checking Payment Status...';
    }

    if (_isSuccessStatus()) {
      return 'Payment Successful!';
    } else if (_isPendingStatus()) {
      return 'Payment Processing';
    } else {
      return 'Payment Failed';
    }
  }

  String _getStatusMessage() {
    if (_isLoadingStatus) {
      return 'Please wait while we verify your payment.';
    }

    if (_isSuccessStatus()) {
      return 'Your wallet has been funded successfully.';
    } else if (_isPendingStatus()) {
      return 'Please wait while we confirm your payment. This may take a few moments.';
    } else {
      return 'Your payment could not be processed. Please try again or contact support.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: BlocManager<WalletCubit, BaseState<WalletData>>(
        bloc: context.read<WalletCubit>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: false,
        child: const SizedBox.shrink(),
        builder: (context, state) {
          final walletData = state.data ?? const WalletData();

          return SafeArea(
            child: Padding(
              padding: AppSpacing.paddingXL,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon with Animation
                  FundingStatusIcon(
                    isLoading: _isLoadingStatus,
                    isSuccess: _isSuccessStatus(),
                    isPending: _isPendingStatus(),
                    scaleAnimation: _scaleAnimation,
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.xxl),

                  // Status Title
                  AppText(
                    _getStatusTitle(),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.sm),

                  // Status Message
                  AppText(
                    _getStatusMessage(),
                    fontSize: AppFontSize.bodyLarge,
                    color: AppColors.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.xxl),

                  // Transaction Details Card
                  TransactionDetailsCard(
                    currency: walletData.currency,
                    amount: widget.amount,
                    availableBalance: walletData.availableBalance,
                    reference: widget.reference,
                    paymentStatus: _paymentStatus,
                    isSuccess: _isSuccessStatus(),
                    isPending: _isPendingStatus(),
                    isLoading: _isLoadingStatus,
                  ),

                  const Spacer(),

                  // Action Buttons
                  FundingActionButtons(
                    isSuccess: _isSuccessStatus(),
                    isFailed: _isFailedStatus(),
                    isPending: _isPendingStatus(),
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.md),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
