import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class MessagesEmptyState extends StatelessWidget {
  const MessagesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.disabled,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText.bodyLarge(
            'No messages yet',
            color: AppColors.textSecondary,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            'Start the conversation!',
            color: AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}
