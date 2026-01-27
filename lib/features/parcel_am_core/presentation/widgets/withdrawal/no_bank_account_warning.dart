import 'package:flutter/material.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';

class NoBankAccountWarning extends StatelessWidget {
  const NoBankAccountWarning({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: AppRadius.sm,
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              Expanded(
                child: AppText.bodyMedium(
                  'Please add a bank account first',
                  color: AppColors.warningDark,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        SizedBox(
          width: double.infinity,
          child: AppButton.primary(
            onPressed: () {
              sl<NavigationService>().navigateTo(
                Routes.bankAccounts,
                arguments: {'userId': userId},
              );
            },
            leadingIcon: Icon(Icons.add, color: AppColors.white),
            child: const AppText('Add Bank Account', color: AppColors.white),
          ),
        ),
      ],
    );
  }
}
