import 'package:flutter/material.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/services/auth/kyc_guard.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';

/// Reactive button that automatically updates based on realtime KYC status changes
class KycRequiredButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool allowPending;

  const KycRequiredButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.allowPending = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to reactively update button based on KYC status changes
    return StreamBuilder<KycStatus>(
      stream: context.watchKycStatus,
      builder: (context, snapshot) {
        // Show loading state while waiting for status
        if (!snapshot.hasData) {
          return AppButton.primary(
            onPressed: null,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final status = snapshot.data!;
        final canProceed = status == KycStatus.approved ||
            (allowPending && (status == KycStatus.pending || status == KycStatus.underReview));

        return AppButton.primary(
          onPressed: canProceed ? onPressed : () => _handleKycBlocked(context, status),
          child: AppText.bodyMedium(text),
        );
      },
    );
  }

  void _handleKycBlocked(BuildContext context, KycStatus status) {
    sl<NavigationService>().navigateTo(
      Routes.kycBlocked,
      arguments: {'status': status},
    );
  }
}
