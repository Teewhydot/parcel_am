import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../bloc/totp_data.dart';
import '../recovery_codes_widget.dart';

class RecoveryCodesStep extends StatelessWidget {
  const RecoveryCodesStep({
    super.key,
    required this.totpData,
    required this.onAcknowledged,
  });

  final TotpData totpData;
  final VoidCallback onAcknowledged;

  @override
  Widget build(BuildContext context) {
    final recoveryCodes = totpData.setupResult?.recoveryCodes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppRadius.md,
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge(
                      '2FA Enabled Successfully!',
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    AppText.bodySmall(
                      'Save your recovery codes below.',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.xl),
        RecoveryCodesWidget(
          recoveryCodes: recoveryCodes,
          onAcknowledged: onAcknowledged,
          isSetupMode: true,
        ),
      ],
    );
  }
}
