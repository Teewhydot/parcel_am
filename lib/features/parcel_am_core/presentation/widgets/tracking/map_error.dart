import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';

class MapError extends StatelessWidget {
  const MapError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      height: 250,
      variant: ContainerVariant.filled,
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: AppRadius.md,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText.bodyMedium(
              message,
              color: AppColors.error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
