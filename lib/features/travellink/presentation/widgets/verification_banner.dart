import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../data/providers/auth_provider.dart';

class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AppCard.elevated(
          child: Row(
            children: [
              AppContainer(
                padding: const EdgeInsets.all(8),
                variant: ContainerVariant.filled,
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                child: const Icon(
                  Icons.warning_outlined,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              AppSpacing.horizontalMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(
                      'Complete Verification',
                      fontWeight: FontWeight.w600,
                    ),
                    AppText.bodySmall(
                      'Verify your identity to start sending packages',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppButton.primary(
                onPressed: () {
                  sl<NavigationService>().navigateTo(Routes.verification);
                },
                size: ButtonSize.small,
                child: AppText.labelMedium(
                  'Verify',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}