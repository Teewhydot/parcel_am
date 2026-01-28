import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';

class NotificationSectionHeader extends StatelessWidget {
  final String title;

  const NotificationSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: AppText.bodySmall(
        title.toUpperCase(),
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
