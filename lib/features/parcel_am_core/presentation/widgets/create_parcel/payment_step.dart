import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../injection_container.dart';
import '../../../../escrow/domain/entities/escrow_status.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../bloc/escrow/escrow_cubit.dart';
import '../../bloc/escrow/escrow_state.dart';
import 'payment_row.dart';

class PaymentStep extends StatelessWidget {
  const PaymentStep({
    super.key,
    required this.createdParcel,
  });

  final ParcelEntity? createdParcel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EscrowCubit, BaseState<EscrowData>>(
      builder: (context, escrowState) {
        return SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 80,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppText.headlineSmall(
                'Parcel Created!',
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyMedium(
                'Your parcel has been created successfully. Complete payment to proceed.',
                textAlign: TextAlign.center,
                color: AppColors.onSurfaceVariant,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              if (createdParcel != null)
                AppCard.elevated(
                  child: Column(
                    children: [
                      PaymentRow(
                        label: 'Delivery Fee',
                        amount: '₦${createdParcel!.price}',
                      ),
                      const PaymentRow(
                        label: 'Service Fee',
                        amount: '₦150',
                      ),
                      const Divider(),
                      PaymentRow(
                        label: 'Total',
                        amount: '₦${(createdParcel!.price ?? 0) + 150}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              _EscrowStatusCard(
                status: escrowState.data?.currentEscrow?.status,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppButton.primary(
                onPressed: escrowState.data?.currentEscrow?.status ==
                            EscrowStatus.pending ||
                        escrowState.data?.currentEscrow?.status ==
                            EscrowStatus.error
                    ? () {
                        if (createdParcel != null) {
                          sl<NavigationService>().navigateTo(Routes.payment);
                        }
                      }
                    : null,
                fullWidth: true,
                child: AppText.bodyMedium(
                  'Proceed to Payment',
                  color: Colors.white,
                ),
              ),
              if (escrowState.data?.currentEscrow?.status ==
                  EscrowStatus.held) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                AppButton.outline(
                  onPressed: () => Navigator.of(context).pop(),
                  fullWidth: true,
                  child: AppText.bodyMedium('Done', color: AppColors.primary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EscrowStatusCard extends StatelessWidget {
  const _EscrowStatusCard({required this.status});

  final EscrowStatus? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getEscrowIcon(status),
            color: AppColors.primary,
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  _getEscrowStatusText(status),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                AppText.bodySmall(
                  _getEscrowDescriptionText(status),
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (status == EscrowStatus.holding)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  IconData _getEscrowIcon(EscrowStatus? status) {
    if (status == null) return Icons.shield;
    switch (status) {
      case EscrowStatus.holding:
        return Icons.hourglass_bottom;
      case EscrowStatus.held:
        return Icons.lock;
      case EscrowStatus.releasing:
        return Icons.hourglass_bottom;
      case EscrowStatus.released:
        return Icons.check_circle;
      case EscrowStatus.error:
        return Icons.error;
      default:
        return Icons.shield;
    }
  }

  String _getEscrowStatusText(EscrowStatus? status) {
    if (status == null) return 'Escrow Protection';
    switch (status) {
      case EscrowStatus.holding:
        return 'Securing Payment...';
      case EscrowStatus.held:
        return 'Payment Secured';
      case EscrowStatus.releasing:
        return 'Releasing Payment...';
      case EscrowStatus.released:
        return 'Payment Released';
      case EscrowStatus.error:
        return 'Payment Error';
      default:
        return 'Escrow Protection';
    }
  }

  String _getEscrowDescriptionText(EscrowStatus? status) {
    if (status == null) return 'Your payment will be securely held until delivery';
    switch (status) {
      case EscrowStatus.holding:
        return 'Please wait while we secure your payment';
      case EscrowStatus.held:
        return 'Your payment is safely held in escrow';
      case EscrowStatus.releasing:
        return 'Releasing payment to carrier';
      case EscrowStatus.released:
        return 'Payment has been released successfully';
      case EscrowStatus.error:
        return 'An error occurred. Please try again';
      default:
        return 'Your payment will be securely held until delivery';
    }
  }
}
