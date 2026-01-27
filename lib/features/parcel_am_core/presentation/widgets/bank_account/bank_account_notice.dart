import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class BankAccountNotice extends StatelessWidget {
  const BankAccountNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.infoDark, size: 20),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          Expanded(
            child: AppText(
              'You can only add bank accounts registered in your name.',
              variant: TextVariant.bodySmall,
              fontSize: AppFontSize.md,
              color: AppColors.infoDark,
            ),
          ),
        ],
      ),
    );
  }
}
