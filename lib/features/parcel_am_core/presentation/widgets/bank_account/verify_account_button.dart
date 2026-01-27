import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class VerifyAccountButton extends StatelessWidget {
  const VerifyAccountButton({
    super.key,
    required this.isVerified,
    required this.isVerifying,
    required this.isDisabled,
    required this.onPressed,
  });

  final bool isVerified;
  final bool isVerifying;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton.outline(
        onPressed: isVerified || isVerifying || isDisabled ? null : onPressed,
        loading: isVerifying,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isVerified)
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            if (isVerified) AppSpacing.horizontalSpacing(SpacingSize.xs),
            AppText.bodyMedium(isVerified ? 'Verified' : 'Verify Account'),
          ],
        ),
      ),
    );
  }
}
