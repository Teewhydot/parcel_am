import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../injection_container.dart';

class FundingActionButtons extends StatelessWidget {
  const FundingActionButtons({
    super.key,
    required this.isSuccess,
    required this.isFailed,
    required this.isPending,
  });

  final bool isSuccess;
  final bool isFailed;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    if (isSuccess) {
      return AppButton.primary(
        onPressed: () {
          sl<NavigationService>().goBack();
          sl<NavigationService>().goBack();
        },
        child: const AppText(
          'Back to Wallet',
          color: AppColors.white,
          fontSize: AppFontSize.bodyLarge,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (isFailed) {
      return Column(
        children: [
          AppButton.primary(
            onPressed: () {
              sl<NavigationService>().goBack();
              sl<NavigationService>().goBack();
              sl<NavigationService>().goBack();
            },
            child: const AppText(
              'Try Again',
              color: AppColors.white,
              fontSize: AppFontSize.bodyLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppButton.secondary(
            onPressed: () {
              sl<NavigationService>().goBack();
              sl<NavigationService>().goBack();
            },
            child: const AppText(
              'Back to Wallet',
              color: AppColors.onSurface,
              fontSize: AppFontSize.bodyLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (isPending) {
      return AppButton.secondary(
        onPressed: () {
          sl<NavigationService>().goBack();
          sl<NavigationService>().goBack();
        },
        child: const AppText(
          'Back to Wallet',
          color: AppColors.onSurface,
          fontSize: AppFontSize.bodyLarge,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
