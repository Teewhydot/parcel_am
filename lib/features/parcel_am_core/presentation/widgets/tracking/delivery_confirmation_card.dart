import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../domain/entities/package_entity.dart';
import '../../bloc/package/package_bloc.dart';
import '../../bloc/package/package_event.dart';
import '../../bloc/package/package_state.dart';

class DeliveryConfirmationCard extends StatelessWidget {
  const DeliveryConfirmationCard({
    super.key,
    required this.package,
    required this.confirmationCodeController,
  });

  static const double _loadingIndicatorSize = 20.0;

  final PackageEntity package;
  final TextEditingController confirmationCodeController;

  @override
  Widget build(BuildContext context) {
    return BlocManager<PackageBloc, BaseState<PackageData>>(
      bloc: context.read<PackageBloc>(),
      showLoadingIndicator: false,
      child: const SizedBox.shrink(),
      builder: (context, state) {
        final data = state.data;
        return AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleMedium('Delivery Confirmation'),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodySmall('Enter the confirmation code to release escrow funds.', color: AppColors.onSurfaceVariant),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput(
                controller: confirmationCodeController,
                label: 'Confirmation Code',
                prefixIcon: const Icon(Icons.verified_user),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  onPressed: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? null
                      : () {
                          if (confirmationCodeController.text.isNotEmpty) {
                            context.read<PackageBloc>().add(
                                  DeliveryConfirmationRequested(
                                    packageId: package.id,
                                    confirmationCode: confirmationCodeController.text,
                                  ),
                                );
                            context.read<PackageBloc>().add(
                                  EscrowReleaseRequested(
                                    packageId: package.id,
                                    transactionId: package.paymentInfo!.transactionId,
                                  ),
                                );
                          }
                        },
                  child: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? const SizedBox(
                          width: _loadingIndicatorSize,
                          height: _loadingIndicatorSize,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const AppText('Confirm & Release Escrow', color: AppColors.white),
                ),
              ),
              if (data?.escrowReleaseStatus == EscrowReleaseStatus.released) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                AppContainer(
                  padding: AppSpacing.paddingMD,
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.sm,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      Expanded(
                        child: AppText.bodySmall('Escrow released successfully!', color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
