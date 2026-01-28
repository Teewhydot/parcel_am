import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';

/// Empty state widget for the chats list screen.
///
/// Displayed when the user has no chat conversations.
class ChatsEmptyState extends StatelessWidget {
  const ChatsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
            AppText.titleLarge(
              'No conversations yet',
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppText.bodyMedium(
              'Start chatting with someone by accepting or creating a delivery request',
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
