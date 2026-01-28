import 'package:flutter/material.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/kyc_status.dart';

class KycActionButton extends StatelessWidget {
  final KycStatus status;

  const KycActionButton({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final String buttonText;
    final VoidCallback? onPressed;

    switch (status) {
      case KycStatus.notStarted:
      case KycStatus.incomplete:
        buttonText = 'Start Verification';
        onPressed = () =>
            sl<NavigationService>().navigateAndReplace(Routes.verification);
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        buttonText = 'Check Status';
        onPressed = () =>
            sl<NavigationService>().navigateAndReplace(Routes.verification);
        break;
      case KycStatus.rejected:
        buttonText = 'Resubmit Documents';
        onPressed = () =>
            sl<NavigationService>().navigateAndReplace(Routes.verification);
        break;
      case KycStatus.approved:
        buttonText = 'Continue';
        onPressed = () => sl<NavigationService>().goBack();
        break;
    }

    return AppButton(
      onPressed: onPressed,
      child: AppText.bodyMedium(buttonText),
    );
  }
}
