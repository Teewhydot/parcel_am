import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';

class ChatsListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatsListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleLarge(
            'Messages',
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Search functionality
          },
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.onSurface,
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.xs),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
