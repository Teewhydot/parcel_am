import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';

class EscrowStepItem extends StatelessWidget {
  const EscrowStepItem({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    required this.color,
  });

  final int step;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.md,
          ),
          child: Center(
            child: AppText.bodySmall(
              step.toString(),
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(
                title,
                fontWeight: FontWeight.w600,
              ),
              AppText.bodySmall(
                description,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
