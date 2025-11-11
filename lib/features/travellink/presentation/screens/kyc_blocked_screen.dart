import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/auth/kyc_guard.dart';

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
              const AppSpacing.verticalLarge(),
              _buildTitle(status),
              const AppSpacing.verticalMedium(),
              _buildDescription(status),
              const AppSpacing.verticalExtraLarge(),
              _buildActionButton(status, context),
              if (status != KycStatus.pending) ...[
                const AppSpacing.verticalMedium(),
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
      case KycStatus.pending:
        icon = Icons.pending_outlined;
        color = AppColors.primary;
        break;
      case KycStatus.rejected:
        icon = Icons.cancel_outlined;
        color = AppColors.error;
        break;
      case KycStatus.verified:
        icon = Icons.verified;
        color = AppColors.success;
        break;
      case KycStatus.unknown:
      default:
        icon = Icons.help_outline;
        color = AppColors.textSecondary;
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
      case KycStatus.pending:
        title = 'Verification Pending';
        break;
      case KycStatus.rejected:
        title = 'Verification Rejected';
        break;
      case KycStatus.verified:
        title = 'Account Verified';
        break;
      case KycStatus.unknown:
      default:
        title = 'Verification Status Unknown';
        break;
    }

    return AppText.headingLarge(
      title,
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
      case KycStatus.pending:
        description =
            'Your identity verification is currently being reviewed. This typically takes 24-48 hours. We\'ll notify you once your verification is complete.';
        break;
      case KycStatus.rejected:
        description =
            'Your identity verification was unsuccessful. Please review your information and resubmit your documents. Contact support if you need assistance.';
        break;
      case KycStatus.verified:
        description =
            'Your account is verified! You now have full access to all platform features.';
        break;
      case KycStatus.unknown:
      default:
        description =
            'We couldn\'t determine your verification status. Please try again or contact support for assistance.';
        break;
    }

    return AppText.bodyMedium(
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
        buttonText = 'Start Verification';
        onPressed = () => Get.offNamed(Routes.verification);
        break;
      case KycStatus.pending:
        buttonText = 'Check Status';
        onPressed = () => Get.offNamed(Routes.verification);
        break;
      case KycStatus.rejected:
        buttonText = 'Resubmit Documents';
        onPressed = () => Get.offNamed(Routes.verification);
        break;
      case KycStatus.verified:
        buttonText = 'Continue';
        onPressed = () => Get.back();
        break;
      case KycStatus.unknown:
      default:
        buttonText = 'Go to Verification';
        onPressed = () => Get.offNamed(Routes.verification);
        break;
    }

    return AppButton.primary(
      onPressed: onPressed,
      text: buttonText,
      fullWidth: true,
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return AppButton.secondary(
      onPressed: () => Get.offNamed(Routes.dashboard),
      text: 'Back to Dashboard',
      fullWidth: true,
    );
  }
}
