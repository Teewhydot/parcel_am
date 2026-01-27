import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../bloc/parcel/parcel_cubit.dart';
import '../delivery_confirmation_card.dart';

class ParcelCard extends StatelessWidget {
  final ParcelEntity parcel;

  const ParcelCard({super.key, required this.parcel});

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        // Navigate to parcel details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ParcelHeader(parcel: parcel),
          AppSpacing.verticalSpacing(SpacingSize.md),
          _ParcelInfoRow(parcel: parcel),
          if (parcel.escrowId != null) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            _EscrowBadge(parcel: parcel),
          ],
          if (_isTrackable(parcel.status)) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            _TrackButton(parcelId: parcel.id),
          ],
          if (parcel.status == ParcelStatus.awaitingConfirmation)
            DeliveryConfirmationCard(parcel: parcel),
          if (parcel.status.canBeCancelled) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            _CancelButton(
              onCancel: () => _showCancelConfirmation(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: AppText.titleMedium('Cancel Parcel'),
          content: AppText.bodyMedium(
            'Are you sure you want to cancel this parcel? The held amount will be returned to your available balance.',
          ),
          actions: [
            AppButton.text(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: AppText.labelMedium('No, Keep It'),
            ),
            AppButton.primary(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _cancelParcel(context);
              },
              child: AppText.labelMedium('Yes, Cancel', color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  void _cancelParcel(BuildContext context) {
    final totalAmount = (parcel.price ?? 0.0) + 150.0;
    context.read<ParcelCubit>().cancelParcel(
          parcelId: parcel.id,
          userId: parcel.sender.userId,
          amount: totalAmount,
          reason: 'User requested cancellation',
        );
  }

  bool _isTrackable(ParcelStatus status) {
    return switch (status) {
      ParcelStatus.pickedUp => true,
      ParcelStatus.inTransit => true,
      ParcelStatus.arrived => true,
      _ => false,
    };
  }
}

class _ParcelHeader extends StatelessWidget {
  const _ParcelHeader({required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(parcel.status).withValues(alpha: 0.1),
            borderRadius: AppRadius.md,
          ),
          child: Icon(
            _getPackageIcon(parcel.status),
            color: _getStatusColor(parcel.status),
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyLarge(
                parcel.description ?? 'Parcel #${parcel.id.substring(0, 8)}',
                fontWeight: FontWeight.w600,
              ),
              AppText.bodyMedium(
                '${parcel.route.origin} → ${parcel.route.destination}',
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        _StatusChip(status: parcel.status),
      ],
    );
  }

  Color _getStatusColor(ParcelStatus status) {
    return switch (status) {
      ParcelStatus.created => AppColors.pending,
      ParcelStatus.paid => AppColors.processing,
      ParcelStatus.pickedUp => AppColors.info,
      ParcelStatus.inTransit => AppColors.reversed,
      ParcelStatus.arrived => AppColors.secondary,
      ParcelStatus.awaitingConfirmation => AppColors.warning,
      ParcelStatus.delivered => AppColors.success,
      ParcelStatus.cancelled => AppColors.error,
      ParcelStatus.disputed => AppColors.warning,
    };
  }

  IconData _getPackageIcon(ParcelStatus status) {
    return switch (status) {
      ParcelStatus.created => Icons.description,
      ParcelStatus.paid => Icons.payment,
      ParcelStatus.pickedUp => Icons.shopping_bag,
      ParcelStatus.inTransit => Icons.local_shipping,
      ParcelStatus.arrived => Icons.place,
      ParcelStatus.awaitingConfirmation => Icons.hourglass_empty,
      ParcelStatus.delivered => Icons.check_circle,
      ParcelStatus.cancelled => Icons.cancel,
      ParcelStatus.disputed => Icons.warning,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ParcelStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: AppText(
        status.displayName,
        variant: TextVariant.bodySmall,
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Color _getStatusColor(ParcelStatus status) {
    return switch (status) {
      ParcelStatus.created => AppColors.pending,
      ParcelStatus.paid => AppColors.processing,
      ParcelStatus.pickedUp => AppColors.info,
      ParcelStatus.inTransit => AppColors.reversed,
      ParcelStatus.arrived => AppColors.secondary,
      ParcelStatus.awaitingConfirmation => AppColors.warning,
      ParcelStatus.delivered => AppColors.success,
      ParcelStatus.cancelled => AppColors.error,
      ParcelStatus.disputed => AppColors.warning,
    };
  }
}

class _ParcelInfoRow extends StatelessWidget {
  const _ParcelInfoRow({required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _InfoItem(Icons.scale, parcel.weight != null ? '${parcel.weight} kg' : 'N/A')),
        Expanded(child: _InfoItem(Icons.category, parcel.category ?? 'General')),
        Expanded(child: _InfoItem(Icons.payments, parcel.price != null ? '₦${parcel.price!.toStringAsFixed(0)}' : 'TBD')),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        AppSpacing.horizontalSpacing(SpacingSize.xs),
        Expanded(
          child: AppText.bodySmall(
            text,
            color: AppColors.onSurfaceVariant,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EscrowBadge extends StatelessWidget {
  const _EscrowBadge({required this.parcel});

  final ParcelEntity parcel;

  Color get _statusColor {
    return switch (parcel.status) {
      ParcelStatus.created => AppColors.pending,
      ParcelStatus.paid => AppColors.processing,
      ParcelStatus.pickedUp => AppColors.info,
      ParcelStatus.inTransit => AppColors.reversed,
      ParcelStatus.arrived => AppColors.secondary,
      ParcelStatus.awaitingConfirmation => AppColors.warning,
      ParcelStatus.delivered => AppColors.success,
      ParcelStatus.cancelled => AppColors.error,
      ParcelStatus.disputed => AppColors.warning,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, size: 16, color: _statusColor),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          AppText.bodySmall(
            'Escrow Protected',
            fontWeight: FontWeight.w500,
            color: _statusColor,
          ),
          const Spacer(),
          if (parcel.price != null)
            AppText.bodySmall(
              '₦${parcel.price!.toStringAsFixed(2)}',
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
        ],
      ),
    );
  }
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({required this.parcelId});

  final String parcelId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton.primary(
        onPressed: () {
          sl<NavigationService>().navigateTo(
            Routes.tracking,
            arguments: {'packageId': parcelId},
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 18, color: Colors.white),
            AppSpacing.horizontalSpacing(SpacingSize.xs),
            AppText.bodyMedium('Track Delivery', color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton.outline(
        onPressed: onCancel,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
            AppSpacing.horizontalSpacing(SpacingSize.xs),
            AppText.bodyMedium('Cancel Parcel', color: AppColors.error),
          ],
        ),
      ),
    );
  }
}
