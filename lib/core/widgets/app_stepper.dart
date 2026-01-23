import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// A horizontal stepper widget showing progress through a multi-step flow.
///
/// Displays step circles with connecting lines and labels below.
/// Supports customizable colors for active, completed, and inactive states.
class AppStepper extends StatelessWidget {
  /// List of step labels to display
  final List<String> steps;

  /// Current active step index (0-based)
  final int currentStep;

  /// Color for completed steps and their connectors
  final Color completedColor;

  /// Color for the active step
  final Color activeColor;

  /// Color for inactive steps and connectors
  final Color inactiveColor;

  /// Color for text on completed/active circles
  final Color circleTextColor;

  /// Color for active step label
  final Color? activeLabelColor;

  /// Color for inactive step labels
  final Color? inactiveLabelColor;

  /// Size of the step circles
  final double circleSize;

  /// Thickness of the connector lines
  final double connectorThickness;

  const AppStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.completedColor = AppColors.success,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.surfaceVariant,
    this.circleTextColor = AppColors.white,
    this.activeLabelColor,
    this.inactiveLabelColor,
    this.circleSize = 32,
    this.connectorThickness = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step circles with connector lines
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            // Even indices are step circles, odd indices are connectors
            if (index.isOdd) {
              return _buildConnector(index ~/ 2);
            }
            return _buildStepCircle(index ~/ 2);
          }),
        ),
        AppSpacing.verticalSpacing(SpacingSize.xs),
        // Step labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, _buildStepLabel),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepIndex) {
    final isActive = stepIndex == currentStep;
    final isCompleted = stepIndex < currentStep;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: isCompleted
            ? completedColor
            : isActive
                ? activeColor
                : inactiveColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: circleTextColor,
                size: circleSize * 0.56,
              )
            : AppText.bodyMedium(
                '${stepIndex + 1}',
                color: isActive ? circleTextColor : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }

  Widget _buildConnector(int stepBeforeIndex) {
    final isConnectorCompleted = stepBeforeIndex < currentStep;

    return Expanded(
      child: Container(
        height: connectorThickness,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isConnectorCompleted ? completedColor : inactiveColor,
      ),
    );
  }

  Widget _buildStepLabel(int stepIndex) {
    final isActive = stepIndex == currentStep;
    final isCompleted = stepIndex < currentStep;

    return AppText.bodySmall(
      steps[stepIndex],
      color: isActive || isCompleted
          ? (activeLabelColor ?? AppColors.onBackground)
          : (inactiveLabelColor ?? AppColors.onSurfaceVariant),
      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
    );
  }
}
