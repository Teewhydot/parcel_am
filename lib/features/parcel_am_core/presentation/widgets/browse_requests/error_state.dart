import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
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
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const AppText(
            'Failed to load requests',
            variant: TextVariant.titleMedium,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            message,
            textAlign: TextAlign.center,
            color: AppColors.onSurfaceVariant,
          ),
          if (onRetry != null) ...[
            AppSpacing.verticalSpacing(SpacingSize.xxl),
            AppButton.primary(
              onPressed: onRetry,
              child: AppText.bodyMedium('Retry', color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
