import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/auth/kyc_guard.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/app_button.dart';

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
      text: text,
    );
  }

  void _handlePress(BuildContext context) {
    final status = checkKycStatus(context);
    
    if (status == KycStatus.verified) {
      onPressed();
      return;
    }
    
    if (allowPending && status == KycStatus.pending) {
      onPressed();
      return;
    }
    
    Get.toNamed(
      Routes.kycBlocked,
      arguments: {'status': status},
    );
  }
}
