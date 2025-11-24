import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.8),
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              AppText.headlineMedium(
                'Settings',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyLarge(
                'Coming Soon',
                color: Colors.white.withOpacity(0.8),
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              Padding(
                padding: AppSpacing.paddingLG,
                child: AppText.bodyMedium(
                  'Settings and preferences will be available here',
                  color: Colors.white.withOpacity(0.7),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
