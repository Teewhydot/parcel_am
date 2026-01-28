import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/kyc_status.dart';

class KycDescription extends StatelessWidget {
  final KycStatus status;

  const KycDescription({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final String description;

    switch (status) {
      case KycStatus.notStarted:
        description =
            'This feature requires identity verification. Please complete your KYC verification to access this feature and unlock full platform capabilities.';
        break;
      case KycStatus.incomplete:
        description =
            'Your verification is incomplete. Please complete all required steps to access this feature.';
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        description =
            'Your identity verification is currently being reviewed. This typically takes 24-48 hours. We\'ll notify you once your verification is complete.';
        break;
      case KycStatus.rejected:
        description =
            'Your identity verification was unsuccessful. Please review your information and resubmit your documents. Contact support if you need assistance.';
        break;
      case KycStatus.approved:
        description =
            'Your account is verified! You now have full access to all platform features.';
        break;
    }

    return AppText(
      description,
      textAlign: TextAlign.center,
      color: AppColors.textSecondary,
    );
  }
}
