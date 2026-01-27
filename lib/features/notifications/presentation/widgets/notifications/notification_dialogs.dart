import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text.dart';

class NotificationDeleteDialog extends StatelessWidget {
  const NotificationDeleteDialog({
    super.key,
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NotificationDeleteDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText.titleMedium(
        'Delete Notification',
        fontWeight: FontWeight.w600,
      ),
      content: AppText.bodyMedium(
        'Are you sure you want to delete this notification?',
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(context),
          child: AppText.bodyMedium('Cancel', color: AppColors.primary),
        ),
        AppButton.text(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: AppText.bodyMedium('Delete', color: AppColors.error),
        ),
      ],
    );
  }
}

class NotificationClearAllDialog extends StatelessWidget {
  const NotificationClearAllDialog({
    super.key,
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NotificationClearAllDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText.titleMedium(
        'Clear All Notifications',
        fontWeight: FontWeight.w600,
      ),
      content: AppText.bodyMedium(
        'Are you sure you want to clear all notifications? This action cannot be undone.',
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(context),
          child: AppText.bodyMedium('Cancel', color: AppColors.primary),
        ),
        AppButton.text(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: AppText.bodyMedium('Clear All', color: AppColors.error),
        ),
      ],
    );
  }
}
