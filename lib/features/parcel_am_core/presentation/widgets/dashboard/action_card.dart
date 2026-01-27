import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_icon.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.surface,
      color: color,
      height: 170,
      padding: AppSpacing.paddingSM,
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.filled(
            icon: icon,
            size: IconSize.medium,
            backgroundColor: AppColors.white.withValues(alpha: 0.3),
            color: AppColors.white,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.titleMedium(
            title,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodySmall(
            subtitle,
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}
