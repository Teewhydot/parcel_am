import 'package:flutter/material.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';

class KycSecondaryButton extends StatelessWidget {
  const KycSecondaryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      onPressed: () =>
          sl<NavigationService>().navigateAndReplace(Routes.home),
      child: AppText.bodyMedium('Back to Home'),
    );
  }
}
