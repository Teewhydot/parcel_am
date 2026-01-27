import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';

class MapLoading extends StatelessWidget {
  const MapLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      height: 250,
      variant: ContainerVariant.filled,
      color: AppColors.textSecondary.withValues(alpha: 0.1),
      borderRadius: AppRadius.md,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText.bodyMedium('Loading map...', color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
