import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/routes/routes.dart';

class KycBlockedScreen extends StatelessWidget {
  const KycBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>?;
    final KycStatus status = arguments?['status'] ?? KycStatus.notStarted;

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(status),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              _buildTitle(status),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              _buildDescription(status),
              AppSpacing.verticalSpacing(SpacingSize.xxxl),
              _buildActionButton(status, context),
              if (status != KycStatus.pending) ...[
                AppSpacing.verticalSpacing(SpacingSize.lg),
                _buildSecondaryButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(KycStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case KycStatus.notStarted:
        icon = Icons.verified_user_outlined;
        color = AppColors.warning;
        break;
      case KycStatus.incomplete:
        icon = Icons.info_outlined;
        color = AppColors.warning;
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        icon = Icons.pending_outlined;
        color = AppColors.primary;
        break;
      case KycStatus.rejected:
        icon = Icons.cancel_outlined;
        color = AppColors.error;
        break;
      case KycStatus.approved:
        icon = Icons.verified;
        color = AppColors.success;
        break;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: color,
      ),
    );
  }

  Widget _buildTitle(KycStatus status) {
    String title;

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

  Widget _buildDescription(KycStatus status) {
    String description;

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

  Widget _buildActionButton(KycStatus status, BuildContext context) {
    String buttonText;
    VoidCallback? onPressed;

    switch (status) {
      case KycStatus.notStarted:
      case KycStatus.incomplete:
        buttonText = 'Start Verification';
        onPressed = () => Get.offNamed(Routes.verification);
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        buttonText = 'Check Status';
        onPressed = () => Get.offNamed(Routes.verification);
        break;
      case KycStatus.rejected:
        buttonText = 'Resubmit Documents';
        onPressed = () => Get.offNamed(Routes.verification);
        break;
      case KycStatus.approved:
        buttonText = 'Continue';
        onPressed = () => Get.back();
        break;
    }

    return AppButton(
      onPressed: onPressed,
      child: Text(buttonText),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return AppButton(
      onPressed: () => Get.offNamed(Routes.home),
      child: const Text('Back to Home'),
    );
  }
}
