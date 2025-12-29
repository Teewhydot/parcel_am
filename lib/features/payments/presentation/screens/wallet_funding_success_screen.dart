import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../parcel_am_core/presentation/bloc/wallet/wallet_bloc.dart';
import '../../../parcel_am_core/presentation/bloc/wallet/wallet_data.dart';
import '../../../../core/bloc/base/base_state.dart';

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
  final nav = GetIt.instance<NavigationService>();

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
    return _paymentStatus == 'success' ||
        _paymentStatus == 'confirmed' ||
        _paymentStatus == 'completed';
  }

  bool _isPendingStatus() {
    return _paymentStatus == 'pending';
  }

  bool _isFailedStatus() {
    return _paymentStatus == 'failed' ||
        _paymentStatus == 'cancelled' ||
        _paymentStatus == 'expired';
  }

  Widget _buildStatusIcon() {
    if (_isLoadingStatus) {
      return const CircularProgressIndicator();
    }

    if (_isSuccessStatus()) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 80,
            color: AppColors.successDark,
          ),
        ),
      );
    } else if (_isPendingStatus()) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.pendingLight,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pendingDark),
              ),
            ),
            const Icon(
              Icons.hourglass_empty,
              size: 40,
              color: AppColors.pendingDark,
            ),
          ],
        ),
      );
    } else {
      // Failed status
      return ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            size: 80,
            color: AppColors.errorDark,
          ),
        ),
      );
    }
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
      body: BlocBuilder<WalletBloc, BaseState<WalletData>>(
        builder: (context, state) {
          final walletData = state.data ?? const WalletData();

          return SafeArea(
            child: Padding(
              padding: AppSpacing.paddingXL,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon with Animation
                  _buildStatusIcon(),

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
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingXL,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withAlpha((0.2 * 255).toInt()),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Amount
                        const AppText(
                          'Amount',
                          fontSize: AppFontSize.bodyMedium,
                          color: AppColors.onSurfaceVariant,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText(
                          '${walletData.currency} ${widget.amount.toStringAsFixed(2)}',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),

                        AppSpacing.verticalSpacing(SpacingSize.lg),

                        // Divider
                        Divider(
                          color: AppColors.outline.withAlpha((0.3 * 255).toInt()),
                        ),

                        AppSpacing.verticalSpacing(SpacingSize.lg),

                        // New Balance (only show for successful payments)
                        if (_isSuccessStatus()) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const AppText(
                                'New Wallet Balance:',
                                fontSize: AppFontSize.bodyMedium,
                                color: AppColors.onSurfaceVariant,
                              ),
                              AppText(
                                '${walletData.currency} ${walletData.availableBalance.toStringAsFixed(2)}',
                                fontSize: AppFontSize.xl,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ],
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.md),
                        ],

                        // Status badge
                        if (!_isLoadingStatus) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const AppText(
                                'Status:',
                                fontSize: AppFontSize.bodySmall,
                                color: AppColors.onSurfaceVariant,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isSuccessStatus()
                                      ? AppColors.success.withOpacity(0.1)
                                      : _isPendingStatus()
                                          ? AppColors.pending.withOpacity(0.1)
                                          : AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AppText(
                                  _paymentStatus.toUpperCase(),
                                  fontSize: AppFontSize.xs,
                                  fontWeight: FontWeight.bold,
                                  color: _isSuccessStatus()
                                      ? AppColors.successDark
                                      : _isPendingStatus()
                                          ? AppColors.pendingDark
                                          : AppColors.errorDark,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.md),
                        ],

                        // Transaction Reference
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText(
                              'Reference:',
                              fontSize: AppFontSize.bodySmall,
                              color: AppColors.onSurfaceVariant,
                            ),
                            AppText(
                              widget.reference,
                              fontSize: AppFontSize.bodySmall,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Action Buttons
                  if (_isSuccessStatus())
                    AppButton.primary(
                      onPressed: () {
                        nav.goBack();
                        nav.goBack();
                      },
                      child: const AppText(
                        'Back to Wallet',
                        color: AppColors.white,
                        fontSize: AppFontSize.bodyLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (_isFailedStatus())
                    Column(
                      children: [
                        AppButton.primary(
                          onPressed: () {
                            nav.goBack();
                            nav.goBack();
                            nav.goBack();
                          },
                          child: const AppText(
                            'Try Again',
                            color: AppColors.white,
                            fontSize: AppFontSize.bodyLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        AppButton.secondary(
                          onPressed: () {
                            nav.goBack();
                            nav.goBack();
                          },
                          child: const AppText(
                            'Back to Wallet',
                            color: AppColors.onSurface,
                            fontSize: AppFontSize.bodyLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else if (_isPendingStatus())
                    AppButton.secondary(
                      onPressed: () {
                        nav.goBack();
                        nav.goBack();
                      },
                      child: const AppText(
                        'Back to Wallet',
                        color: AppColors.onSurface,
                        fontSize: AppFontSize.bodyLarge,
                        fontWeight: FontWeight.w600,
                      ),
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
