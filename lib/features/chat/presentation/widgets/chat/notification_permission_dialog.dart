import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NotificationPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.info),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          AppText.titleMedium('Enable Notifications'),
        ],
      ),
      content: AppText.bodyLarge(
        'Stay connected with your conversations! Enable notifications to receive instant alerts when you receive new messages, even when the app is closed.',
      ),
      actions: <Widget>[
        AppButton.text(
          child: AppText.bodyMedium('Not Now'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        AppButton.primary(
          child: AppText.bodyMedium('Enable', color: AppColors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
