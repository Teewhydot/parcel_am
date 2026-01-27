import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class NotificationErrorState extends StatelessWidget {
  const NotificationErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText.bodyMedium(message),
          if (onRetry != null) ...[
            AppSpacing.verticalSpacing(SpacingSize.lg),
            AppButton.primary(
              onPressed: onRetry,
              child: AppText.bodyMedium('Retry', color: AppColors.white),
            ),
          ],
        ],
      ),
    );
  }
}
