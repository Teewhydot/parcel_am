import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/services/auth/kyc_guard.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../travellink/domain/entities/user_entity.dart';

/// Example widget demonstrating KYC check before action
class KycRequiredButton extends StatelessWidget with KycCheckMixin {
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
    return AppButton.primary(
      onPressed: () => _handlePress(context),
      child: Text(text),
    );
  }

  void _handlePress(BuildContext context) {
    final status = checkKycStatus(context);

    if (status == KycStatus.approved) {
      onPressed();
      return;
    }

    if (allowPending && (status == KycStatus.pending || status == KycStatus.underReview)) {
      onPressed();
      return;
    }
    
    Get.toNamed(
      Routes.kycBlocked,
      arguments: {'status': status},
    );
  }
}
