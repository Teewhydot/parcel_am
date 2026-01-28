import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_stepper.dart';

class SetupStepper extends StatelessWidget {
  const SetupStepper({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return AppStepper(
      steps: const ['Scan QR', 'Verify', 'Save Codes'],
      currentStep: currentStep,
    );
  }
}
