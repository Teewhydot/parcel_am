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

class DisputeEscrowCard extends StatelessWidget {
  const DisputeEscrowCard({
    super.key,
    required this.package,
    required this.disputeReasonController,
  });

  static const double _loadingIndicatorSize = 20.0;

  final PackageEntity package;
  final TextEditingController disputeReasonController;

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
              Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error, size: 20),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  AppText.titleMedium('Dispute Escrow'),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodySmall('If there\'s an issue with the delivery, you can file a dispute.', color: AppColors.onSurfaceVariant),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput.multiline(
                controller: disputeReasonController,
                label: 'Reason for Dispute',
                hintText: 'Please explain the issue...',
                maxLines: 3,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              SizedBox(
                width: double.infinity,
                child: AppButton.outline(
                  onPressed: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? null
                      : () {
                          if (disputeReasonController.text.isNotEmpty) {
                            context.read<PackageBloc>().add(
                                  EscrowDisputeRequested(
                                    packageId: package.id,
                                    transactionId: package.paymentInfo!.transactionId,
                                    reason: disputeReasonController.text,
                                  ),
                                );
                          }
                        },
                  child: data?.escrowReleaseStatus == EscrowReleaseStatus.processing
                      ? const SizedBox(
                          width: _loadingIndicatorSize,
                          height: _loadingIndicatorSize,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const AppText('File Dispute'),
                ),
              ),
              if (data?.escrowReleaseStatus == EscrowReleaseStatus.disputed) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                AppContainer(
                  padding: AppSpacing.paddingMD,
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: AppRadius.sm,
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: AppColors.accent),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bodySmall('Dispute filed successfully', color: AppColors.accent, fontWeight: FontWeight.bold),
                            if (data?.disputeId != null)
                              AppText.bodySmall('Dispute ID: ${data!.disputeId}', color: AppColors.onSurfaceVariant),
                          ],
                        ),
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
