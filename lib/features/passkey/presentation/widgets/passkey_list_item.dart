import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/passkey_entity.dart';

/// Widget displaying a single passkey in a list
class PasskeyListItem extends StatelessWidget {
  const PasskeyListItem({
    super.key,
    required this.passkey,
    required this.onRemove,
    this.isLoading = false,
  });

  final PasskeyEntity passkey;
  final VoidCallback onRemove;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fingerprint,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: AppText.bodyLarge(
          passkey.deviceName ?? 'Passkey',
          fontWeight: FontWeight.w600,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalSpacing(SpacingSize.xs),
            AppText(
              'Created ${timeago.format(passkey.createdAt)}',
              variant: TextVariant.bodySmall,
              fontSize: AppFontSize.md,
              color: AppColors.onSurfaceVariant,
            ),
            if (passkey.lastUsedAt != null) ...[
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText.bodySmall(
                'Last used ${timeago.format(passkey.lastUsedAt!)}',
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ],
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                ),
              )
            : IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                onPressed: () => _showRemoveConfirmation(context),
              ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.titleMedium('Remove Passkey'),
        content: AppText.bodyMedium(
          'Are you sure you want to remove ${passkey.deviceName ?? 'this passkey'}? '
          'You will need to add it again to use passkey authentication on this device.',
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.of(context).pop(),
            child: AppText.bodyMedium('Cancel'),
          ),
          AppButton.text(
            onPressed: () {
              Navigator.of(context).pop();
              onRemove();
            },
            child: AppText.bodyMedium('Remove', color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
