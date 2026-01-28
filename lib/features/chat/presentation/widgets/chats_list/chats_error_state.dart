import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';

/// Error state widget for the chats list screen.
///
/// Displays an error icon, message, and a retry button.
class ChatsErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ChatsErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
            AppText.titleMedium(
              'Something went wrong',
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppText.bodyMedium(
              errorMessage,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
            AppButton.primary(
              onPressed: onRetry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 20),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  AppText.bodyMedium('Try Again', color: AppColors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
