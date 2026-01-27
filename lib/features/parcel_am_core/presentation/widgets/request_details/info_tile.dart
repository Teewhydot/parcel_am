import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  label,
                  color: AppColors.onSurfaceVariant,
                ),
                AppText.bodyMedium(
                  value,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
