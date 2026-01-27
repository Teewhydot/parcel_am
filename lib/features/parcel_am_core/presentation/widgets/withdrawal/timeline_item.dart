import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.label,
    required this.timestamp,
    this.isCompleted = false,
    this.isActive = false,
    this.isLast = false,
  });

  final String label;
  final String timestamp;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.onSurfaceVariant.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isCompleted || isActive ? color : AppColors.transparent,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color,
                  ),
                ),
            ],
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    label,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isActive
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  AppText.bodySmall(
                    timestamp,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
