import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../escrow/domain/entities/escrow_status.dart';
import '../../bloc/escrow/escrow_cubit.dart';
import '../../bloc/escrow/escrow_state.dart';
import '../../bloc/wallet/wallet_cubit.dart';
import '../../bloc/wallet/wallet_data.dart';
import 'escrow_step_item.dart';

class EscrowDepositStep extends StatelessWidget {
  const EscrowDepositStep({super.key, required this.totalAmount});

  final String totalAmount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EscrowCubit, BaseState<EscrowData>>(
      builder: (context, escrowState) {
        final escrowStatus = escrowState.data?.currentEscrow?.status;
        return BlocBuilder<WalletCubit, BaseState<WalletData>>(
          builder: (context, walletState) {
            return Column(
              children: [
                if (walletState is LoadedState<WalletData> && walletState.data != null) ...[
                  AppCard.elevated(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppText.bodyLarge(
                              'Wallet Balance',
                              fontWeight: FontWeight.bold,
                            ),
                            const Spacer(),
                            Icon(
                              _getEscrowStatusIcon(escrowStatus),
                              color: _getEscrowStatusColor(escrowStatus),
                              size: 20,
                            ),
                            AppSpacing.horizontalSpacing(SpacingSize.xs),
                            AppText(
                              _getEscrowStatusLabel(escrowStatus),
                              variant: TextVariant.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: _getEscrowStatusColor(escrowStatus),
                            ),
                          ],
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText.bodyMedium(
                              'Available Balance',
                              color: AppColors.onSurfaceVariant,
                            ),
                            AppText.bodyLarge(
                              '₦${walletState.data!.availableBalance.toStringAsFixed(2)}',
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText.bodyMedium(
                              'Pending (Escrow)',
                              color: AppColors.onSurfaceVariant,
                            ),
                            AppText.bodyLarge(
                              '₦${walletState.data!.pendingBalance.toStringAsFixed(2)}',
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                ],
                AppCard.elevated(
                  padding: AppSpacing.paddingXXL,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.pill,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      const AppText(
                        'Securing Your Payment',
                        variant: TextVariant.titleMedium,
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.bold,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      AppText.bodyMedium(
                        'Your $totalAmount is being deposited into our secure escrow system',
                        textAlign: TextAlign.center,
                        color: AppColors.onSurfaceVariant,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xxl),
                      LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      AppText.bodySmall(
                        'Processing payment...',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                AppCard.elevated(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyLarge(
                        'How Escrow Protection Works',
                        fontWeight: FontWeight.bold,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      const EscrowStepItem(
                        step: 1,
                        title: 'Payment Secured',
                        description: 'Your money is held safely in escrow',
                        color: AppColors.primary,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      const EscrowStepItem(
                        step: 2,
                        title: 'Package Delivered',
                        description: 'Traveler delivers your package',
                        color: AppColors.secondary,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      const EscrowStepItem(
                        step: 3,
                        title: 'Payment Released',
                        description: 'Money is released to traveler',
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getEscrowStatusIcon(EscrowStatus? status) {
    if (status == null) return Icons.shield;
    switch (status) {
      case EscrowStatus.holding:
        return Icons.hourglass_bottom;
      case EscrowStatus.held:
        return Icons.lock;
      case EscrowStatus.releasing:
        return Icons.lock_open;
      case EscrowStatus.released:
        return Icons.check_circle;
      case EscrowStatus.error:
        return Icons.error;
      default:
        return Icons.shield;
    }
  }

  Color _getEscrowStatusColor(EscrowStatus? status) {
    if (status == null) return AppColors.onSurfaceVariant;
    return switch (status) {
      EscrowStatus.holding => AppColors.pending,
      EscrowStatus.held => AppColors.processing,
      EscrowStatus.releasing => AppColors.reversed,
      EscrowStatus.released => AppColors.success,
      EscrowStatus.error => AppColors.error,
      _ => AppColors.onSurfaceVariant,
    };
  }

  String _getEscrowStatusLabel(EscrowStatus? status) {
    if (status == null) return 'IDLE';
    switch (status) {
      case EscrowStatus.holding:
        return 'HOLDING';
      case EscrowStatus.held:
        return 'HELD';
      case EscrowStatus.releasing:
        return 'RELEASING';
      case EscrowStatus.released:
        return 'RELEASED';
      case EscrowStatus.error:
        return 'ERROR';
      default:
        return 'IDLE';
    }
  }
}
