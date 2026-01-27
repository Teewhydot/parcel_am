import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({
    super.key,
    required this.hasReachedMaxAccounts,
    required this.remainingSlots,
  });

  final bool hasReachedMaxAccounts;
  final int remainingSlots;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: AppColors.infoLight,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.info),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.infoDark),
            AppSpacing.horizontalSpacing(SpacingSize.sm),
            Expanded(
              child: AppText.bodyMedium(
                hasReachedMaxAccounts
                    ? 'Maximum of 5 bank accounts reached'
                    : 'You can add $remainingSlots more account(s)',
                color: AppColors.infoDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
