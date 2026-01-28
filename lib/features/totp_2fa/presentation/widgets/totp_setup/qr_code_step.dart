import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../bloc/totp_data.dart';
import '../totp_qr_code_widget.dart';

class QrCodeStep extends StatelessWidget {
  const QrCodeStep({
    super.key,
    required this.totpData,
    required this.isLoading,
    required this.isAuthenticatorAppAvailable,
    required this.isLaunchingApp,
    required this.onOpenInAuthenticatorApp,
    required this.onContinue,
  });

  final TotpData totpData;
  final bool isLoading;
  final bool isAuthenticatorAppAvailable;
  final bool isLaunchingApp;
  final VoidCallback onOpenInAuthenticatorApp;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final setupResult = totpData.setupResult;
    if (setupResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TotpQrCodeWidget(
          qrCodeUri: setupResult.qrCodeUri,
          secretForDisplay: setupResult.secretForDisplay,
          isAuthenticatorAppAvailable: isAuthenticatorAppAvailable,
          isLaunchingApp: isLaunchingApp,
          onOpenInAuthenticatorApp: onOpenInAuthenticatorApp,
        ),
        AppSpacing.verticalSpacing(SpacingSize.xl),
        AppButton.primary(
          onPressed: isLoading ? null : onContinue,
          fullWidth: true,
          child: AppText.bodyMedium('Continue', color: AppColors.white),
        ),
      ],
    );
  }
}
