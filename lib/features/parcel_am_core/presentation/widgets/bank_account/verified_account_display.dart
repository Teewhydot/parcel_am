import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class VerifiedAccountDisplay extends StatelessWidget {
  const VerifiedAccountDisplay({
    super.key,
    required this.accountName,
  });

  final String accountName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          'Account Name',
          fontWeight: FontWeight.w500,
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: AppRadius.sm,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.successDark),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              Expanded(
                child: AppText.bodyLarge(
                  accountName,
                  fontWeight: FontWeight.w600,
                  color: AppColors.successDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
