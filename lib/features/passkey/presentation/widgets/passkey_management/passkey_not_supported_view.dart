import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

/// View displayed when passkeys are not supported on the device
class PasskeyNotSupportedView extends StatelessWidget {
  const PasskeyNotSupportedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 40,
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            AppText(
              'Passkeys Not Supported',
              variant: TextVariant.titleLarge,
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText.bodyMedium(
              'Your device doesn\'t support passkey authentication. Please update your device or use password login.',
              textAlign: TextAlign.center,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
