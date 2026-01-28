import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../bloc/totp_data.dart';
import '../totp_code_input_widget.dart';

class VerificationStep extends StatelessWidget {
  const VerificationStep({
    super.key,
    required this.totpData,
    required this.isLoading,
    required this.onCodeCompleted,
    required this.onBack,
  });

  final TotpData totpData;
  final bool isLoading;
  final void Function(String)? onCodeCompleted;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: AppRadius.md,
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: AppText.bodyMedium(
                  'Enter the 6-digit code from your authenticator app to verify setup',
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.xl),
        TotpCodeInputWidget(
          onCompleted: isLoading ? null : onCodeCompleted,
          enabled: !isLoading,
          errorMessage: totpData.errorMessage,
          autoFocus: true,
        ),
        AppSpacing.verticalSpacing(SpacingSize.xl),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          AppButton.text(
            onPressed: onBack,
            leadingIcon: const Icon(Icons.arrow_back, size: 18, color: AppColors.primary),
            child: AppText.labelMedium('Back to QR code', color: AppColors.primary),
          ),
      ],
    );
  }
}
