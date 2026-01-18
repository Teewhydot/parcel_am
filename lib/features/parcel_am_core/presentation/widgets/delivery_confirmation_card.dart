import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/helpers/haptic_helper.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parcel_entity.dart';
import '../bloc/parcel/parcel_cubit.dart';
import '../bloc/parcel/parcel_state.dart';

/// A card widget that displays the delivery confirmation action for senders.
///
/// Only shown when parcel status is awaitingConfirmation and user is the sender.
/// Features:
/// - Instructions to contact receiver to verify delivery
/// - Auto-release warning (24-48 hours)
/// - Confirm & Release Payment button
/// - Report Issue button for disputes
class DeliveryConfirmationCard extends StatelessWidget {
  final ParcelEntity parcel;

  const DeliveryConfirmationCard({
    super.key,
    required this.parcel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: SpacingSize.md.value),
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.md,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Confirm Delivery',
                      variant: TextVariant.titleMedium,
                      fontWeight: FontWeight.bold,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    AppText.bodySmall(
                      'The courier has marked your parcel as delivered.',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),

          // Instructions to contact receiver
          Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: AppColors.primary),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      'Contact ${parcel.receiver.name}',
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                GestureDetector(
                  onTap: () {
                    HapticHelper.lightImpact();
                    _handlePhoneCall(parcel.receiver.phoneNumber);
                  },
                  child: Row(
                    children: [
                      AppSpacing.horizontalSpacing(SpacingSize.xxl),
                      AppText(
                        parcel.receiver.phoneNumber,
                        variant: TextVariant.bodyMedium,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                      AppSpacing.horizontalSpacing(SpacingSize.sm),
                      Icon(
                        Icons.call_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.onSurfaceVariant),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    Expanded(
                      child: AppText.bodySmall(
                        'Please verify with the receiver that they have received the parcel before confirming.',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),

          // Auto-release warning
          Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: AppRadius.md,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 20, color: AppColors.warningDark),
                AppSpacing.horizontalSpacing(SpacingSize.sm),
                Expanded(
                  child: AppText.bodySmall(
                    'Payment will auto-release in 24-48 hours if no action is taken.',
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),

          // Action buttons
          BlocBuilder<ParcelCubit, BaseState<ParcelData>>(
            buildWhen: (previous, current) {
              final prevUpdating = previous.data?.updatingParcelId;
              final currUpdating = current.data?.updatingParcelId;
              return prevUpdating != currUpdating;
            },
            builder: (context, state) {
              final isLoading = state.data?.updatingParcelId == parcel.id;

              return Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      onPressed: isLoading ? null : () => _reportIssue(context),
                      child: AppText.bodyMedium(
                        'Report Issue',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      onPressed: isLoading ? null : () => _confirmDelivery(context),
                      loading: isLoading,
                      child: AppText.bodyMedium(
                        'Confirm & Release Payment',
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelivery(BuildContext context) {
    HapticHelper.mediumImpact();

    if (!context.mounted) return;

    // Check if escrowId exists
    if (parcel.escrowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText.bodyMedium(
            'Unable to confirm: No escrow found for this parcel.',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _showConfirmationBottomSheet(context);
  }

  void _showConfirmationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _DeliveryConfirmationSheet(
        parcel: parcel,
        onConfirm: () {
          Navigator.of(bottomSheetContext).pop();
          context.read<ParcelCubit>().confirmDelivery(
            parcel.id,
            parcel.escrowId!,
          );
        },
      ),
    );
  }

  void _reportIssue(BuildContext context) {
    // Show a dialog to report an issue
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: AppText.titleMedium('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(
              'If there is an issue with this delivery, you can:',
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            _buildIssueOption(
              icon: Icons.support_agent,
              title: 'Contact Support',
              description: 'Get help from our support team',
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            _buildIssueOption(
              icon: Icons.gavel,
              title: 'Open Dispute',
              description: 'Dispute this delivery if there\'s a problem',
            ),
          ],
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.of(context).pop(),
            child: AppText.bodyMedium('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueOption({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  title,
                  fontWeight: FontWeight.w600,
                ),
                AppText.bodySmall(
                  description,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Future<void> _handlePhoneCall(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      Logger.logError('Failed to launch phone call: $e', tag: 'DeliveryConfirmationCard');
    }
  }
}

class _DeliveryConfirmationSheet extends StatelessWidget {
  final ParcelEntity parcel;
  final VoidCallback onConfirm;

  const _DeliveryConfirmationSheet({
    required this.parcel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final parcelPrice = parcel.price ?? 0.0;
    final serviceFee = 150.0;
    final totalAmount = parcelPrice + serviceFee;
    final currency = parcel.currency ?? 'NGN';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.topXxl,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: AppRadius.xs,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),

              // Header
              Row(
                children: [
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.md,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleMedium(
                          'Confirm Delivery',
                          fontWeight: FontWeight.bold,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodySmall(
                          'Review the consequences before confirming',
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),

              // Receiver verification prompt
              Container(
                padding: AppSpacing.paddingLG,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.contact_phone, size: 20, color: AppColors.primary),
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        AppText.bodyMedium(
                          'Have you verified with ${parcel.receiver.name}?',
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    AppText.bodySmall(
                      'Make sure the receiver has confirmed they received the parcel in good condition.',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),

              // Consequences section
              AppText.bodyMedium(
                'What happens when you confirm:',
                fontWeight: FontWeight.w600,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),

              // Consequence 1: Payment released
              _buildConsequenceItem(
                icon: Icons.payments,
                iconColor: AppColors.success,
                title: 'Payment Released',
                description: '$currency ${parcelPrice.toStringAsFixed(2)} will be released to the courier\'s available balance.',
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),

              // Consequence 2: Held balance cleared
              _buildConsequenceItem(
                icon: Icons.account_balance_wallet,
                iconColor: AppColors.warning,
                title: 'Held Balance Cleared',
                description: '$currency ${totalAmount.toStringAsFixed(2)} (including service fee) will be removed from your held balance.',
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),

              // Consequence 3: Irreversible
              _buildConsequenceItem(
                icon: Icons.warning_amber,
                iconColor: AppColors.error,
                title: 'This Action is Final',
                description: 'Once confirmed, this action cannot be undone. Only confirm if the delivery is successful.',
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      onPressed: () => Navigator.of(context).pop(),
                      child: AppText.bodyMedium('Cancel'),
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      onPressed: onConfirm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.white,
                            size: 20,
                          ),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          AppText.bodyMedium(
                            'Confirm & Release',
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsequenceItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  title,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText.bodySmall(
                  description,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
