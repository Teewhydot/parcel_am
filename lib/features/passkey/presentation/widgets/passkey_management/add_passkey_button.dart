import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text.dart';

/// Button widget for adding a new passkey
class AddPasskeyButton extends StatelessWidget {
  const AddPasskeyButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      onPressed: isLoading ? null : onPressed,
      loading: isLoading,
      fullWidth: true,
      leadingIcon: const Icon(Icons.add, color: AppColors.white, size: 20),
      child: AppText.bodyMedium('Add New Passkey', color: AppColors.white),
    );
  }
}
