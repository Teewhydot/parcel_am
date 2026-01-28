import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/kyc_status.dart';

class KycTitle extends StatelessWidget {
  final KycStatus status;

  const KycTitle({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final String title;

    switch (status) {
      case KycStatus.notStarted:
        title = 'KYC Verification Required';
        break;
      case KycStatus.incomplete:
        title = 'Complete Your Verification';
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        title = 'Verification Pending';
        break;
      case KycStatus.rejected:
        title = 'Verification Rejected';
        break;
      case KycStatus.approved:
        title = 'Account Verified';
        break;
    }

    return AppText(
      title,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
    );
  }
}
