import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';

/// Widget displaying QR code for TOTP setup
class TotpQrCodeWidget extends StatelessWidget {
  /// The otpauth:// URI to encode in the QR code
  final String qrCodeUri;

  /// The secret key formatted for display
  final String secretForDisplay;

  /// Size of the QR code
  final double size;

  /// Callback when user taps "Open in Authenticator App"
  final VoidCallback? onOpenInAuthenticatorApp;

  /// Whether an authenticator app is available on the device
  final bool isAuthenticatorAppAvailable;

  /// Whether the launcher is currently checking or opening the app
  final bool isLaunchingApp;

  const TotpQrCodeWidget({
    super.key,
    required this.qrCodeUri,
    required this.secretForDisplay,
    this.size = 200,
    this.onOpenInAuthenticatorApp,
    this.isAuthenticatorAppAvailable = false,
    this.isLaunchingApp = false,
  });

  void _copySecret(BuildContext context) {
    final secretToCopy = secretForDisplay.replaceAll(' ', '');
    Clipboard.setData(ClipboardData(text: secretToCopy));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(
          'Secret key copied to clipboard',
          color: AppColors.white,
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodyLarge(
          'Scan this QR code with your authenticator app',
          textAlign: TextAlign.center,
          color: AppColors.onBackground,
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: QrImageView(
            data: qrCodeUri,
            version: QrVersions.auto,
            size: size,
            backgroundColor: AppColors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        // Open in Authenticator App button
        if (isAuthenticatorAppAvailable || onOpenInAuthenticatorApp != null)
          Column(
            children: [
              AppButton.primary(
                onPressed: isLaunchingApp ? null : onOpenInAuthenticatorApp,
                fullWidth: true,
                leadingIcon: isLaunchingApp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: AppColors.white,
                      ),
                child: AppText.labelLarge(
                  isLaunchingApp
                      ? 'Opening...'
                      : 'Open in Authenticator App',
                  color: AppColors.white,
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.horizontalPaddingMD,
                    child: AppText.bodySmall(
                      'or scan manually',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
            ],
          ),
        AppText.bodyMedium(
          'Or enter this key manually:',
          color: AppColors.onSurfaceVariant,
        ),
        AppSpacing.verticalSpacing(SpacingSize.xs),
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SelectableText(
                  secretForDisplay,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.xs),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                onPressed: () => _copySecret(context),
                tooltip: 'Copy secret key',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        AppText.bodySmall(
          'Compatible with Google Authenticator, Authy, 1Password, and other TOTP apps',
          textAlign: TextAlign.center,
          color: AppColors.onSurfaceVariant,
        ),
      ],
    );
  }
}
