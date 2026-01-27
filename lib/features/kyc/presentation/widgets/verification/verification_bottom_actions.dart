import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class VerificationBottomActions extends StatelessWidget {
  const VerificationBottomActions({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
  });

  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: AppSpacing.paddingXL,
      variant: ContainerVariant.outlined,
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: AppButton.outline(
                onPressed: isSubmitting ? null : onBack,
                child: AppText.labelMedium('Back'),
              ),
            ),
          if (currentStep > 0) AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            flex: currentStep > 0 ? 2 : 1,
            child: AppButton.primary(
              onPressed: isSubmitting ? null : onNext,
              loading: isSubmitting,
              child: AppText.labelMedium(
                currentStep == totalSteps - 1 ? 'Submit' : 'Next',
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
