import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/routes/routes.dart';
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                  // Success Icon with Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.xxl),

                  // Success Title
                  const AppText(
                    'Payment Successful!',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.sm),

                  // Success Message
                  AppText(
                    'Your wallet has been funded successfully.',
                    fontSize: 16,
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
                        // Amount Funded
                        const AppText(
                          'Amount Funded',
                          fontSize: 14,
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

                        // New Balance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText(
                              'New Wallet Balance:',
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            AppText(
                              '${walletData.currency} ${walletData.availableBalance.toStringAsFixed(2)}',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ],
                        ),

                        AppSpacing.verticalSpacing(SpacingSize.md),

                        // Transaction Reference
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText(
                              'Reference:',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                            AppText(
                              widget.reference,
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Action Button
                  AppButton.primary(
                    onPressed: () {
                      // Navigate back to wallet screen, removing all previous routes
                      nav.navigateAndReplaceAll(
                        Routes.wallet,
                        arguments: widget.userId,
                      );
                    },
                    child: const AppText(
                      'Back to Wallet',
                      color: AppColors.white,
                      fontSize: 16,
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
