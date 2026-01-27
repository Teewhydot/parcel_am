import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';

class TermsText extends StatelessWidget {
  const TermsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingMD,
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: 'By continuing, you agree to our ',
            ),
            TextSpan(
              text: 'Terms & Privacy Policy',
              style: TextStyle(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
