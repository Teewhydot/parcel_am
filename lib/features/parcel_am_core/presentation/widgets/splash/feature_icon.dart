import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class FeatureIcon extends StatelessWidget {
  const FeatureIcon({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppContainer(
          width: 48,
          height: 48,
          variant: ContainerVariant.filled,
          color: AppColors.white.withValues(alpha: 0.2),
          borderRadius: AppRadius.pill,
          child: Icon(icon, color: AppColors.white, size: 24),
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        AppText.labelSmall(
          title,
          color: AppColors.white.withValues(alpha: 0.8),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
