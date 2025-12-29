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
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(10),
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
            padding: const EdgeInsets.all(12),
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
                  onTap: () => _handlePhoneCall(parcel.receiver.phoneNumber),
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
            padding: const EdgeInsets.all(12),
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
          BlocBuilder<ParcelBloc, BaseState<ParcelData>>(
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

  Future<void> _confirmDelivery(BuildContext context) async {
    await HapticHelper.mediumImpact();

    if (!context.mounted) return;

    final confirmed = await _showConfirmationDialog(context);
    if (!confirmed) return;

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

    context.read<ParcelBloc>().add(
      ParcelConfirmDeliveryRequested(
        parcelId: parcel.id,
        escrowId: parcel.escrowId!,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    await HapticHelper.lightImpact();

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: AppText.titleMedium('Confirm Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Have you verified with ${parcel.receiver.name} that they received the parcel?',
              variant: TextVariant.bodyMedium,
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: AppColors.success,
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodySmall(
                      'This will release ${parcel.currency ?? "NGN"} ${parcel.price?.toStringAsFixed(2) ?? "0.00"} to the courier.',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton.text(
            onPressed: () {
              HapticHelper.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: AppText.bodyMedium('Cancel'),
          ),
          AppButton.primary(
            onPressed: () {
              HapticHelper.mediumImpact();
              Navigator.of(context).pop(true);
            },
            child: AppText.bodyMedium('Yes, Confirm', color: AppColors.white),
          ),
        ],
      ),
    );

    return result ?? false;
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
      padding: const EdgeInsets.all(12),
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
