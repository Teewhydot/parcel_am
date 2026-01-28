import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class ParcelErrorState extends StatelessWidget {
  const ParcelErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyLarge(errorMessage),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppButton.primary(
            onPressed: onRetry,
            child: AppText.bodyMedium('Retry', color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
