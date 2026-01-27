import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../recovery_codes_widget.dart';

class NewRecoveryCodesCard extends StatelessWidget {
  const NewRecoveryCodesCard({
    super.key,
    required this.recoveryCodes,
    required this.onAcknowledged,
  });

  final List<String> recoveryCodes;
  final VoidCallback onAcknowledged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.bodyLarge(
            'New Recovery Codes',
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          RecoveryCodesWidget(
            recoveryCodes: recoveryCodes,
            onAcknowledged: onAcknowledged,
            isSetupMode: true,
          ),
        ],
      ),
    );
  }
}
