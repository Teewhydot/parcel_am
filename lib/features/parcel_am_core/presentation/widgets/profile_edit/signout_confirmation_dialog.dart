import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text.dart';

class SignoutConfirmationDialog extends StatelessWidget {
  const SignoutConfirmationDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const SignoutConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText.titleMedium('Sign Out'),
      content: AppText.bodyMedium(
        'Are you sure you want to sign out of your account?',
      ),
      actions: [
        AppButton.text(
          key: const Key('cancelSignoutButton'),
          onPressed: () => Navigator.of(context).pop(false),
          child: AppText.labelMedium('Cancel', color: AppColors.onSurface),
        ),
        AppButton.primary(
          key: const Key('confirmSignoutButton'),
          onPressed: () => Navigator.of(context).pop(true),
          child: AppText.labelMedium('Sign Out', color: AppColors.white),
        ),
      ],
    );
  }
}
