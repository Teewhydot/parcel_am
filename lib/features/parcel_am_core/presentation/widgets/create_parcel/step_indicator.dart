import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_stepper.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLG,
      color: AppColors.surface,
      child: AppStepper(
        steps: const ['Details', 'Location', 'Review'],
        currentStep: currentStep,
        completedColor: AppColors.primary,
        activeColor: AppColors.primary,
        inactiveColor: AppColors.surfaceVariant,
        activeLabelColor: AppColors.primary,
      ),
    );
  }
}
