import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({
    super.key,
    required this.onSignout,
  });

  final VoidCallback onSignout;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: AppSpacing.paddingMD,
      variant: ContainerVariant.outlined,
      borderRadius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Account',
            variant: TextVariant.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodySmall(
            'Signout from your account',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          SizedBox(
            width: double.infinity,
            child: AppButton.outline(
              key: const Key('signoutButton'),
              onPressed: onSignout,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout,
                    size: 18,
                    color: AppColors.error,
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.xs),
                  AppText.labelMedium(
                    'Sign Out',
                    color: AppColors.error,
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
