import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class BanksLoadingIndicator extends StatelessWidget {
  const BanksLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            'Loading banks...',
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
