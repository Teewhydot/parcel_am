import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../bloc/passkey_bloc.dart';
import '../bloc/passkey_data.dart';
import '../bloc/passkey_event.dart';

/// Card widget for setting up passkey authentication
/// Shows in settings when user hasn't set up a passkey yet
class PasskeySetupCard extends StatelessWidget {
  const PasskeySetupCard({
    super.key,
    this.onSetupComplete,
  });

  final VoidCallback? onSetupComplete;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasskeyBloc, BaseState<PasskeyData>>(
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText.bodyMedium(state.successMessage ?? 'Passkey added successfully!', color: AppColors.white),
              backgroundColor: AppColors.success,
            ),
          );
          onSetupComplete?.call();
        } else if (state.isError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText.bodyMedium(state.errorMessage ?? 'Failed to add passkey', color: AppColors.white),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final passkeyData = state.data ?? const PasskeyData();

        // Don't show if passkeys aren't supported
        if (!passkeyData.isSupported) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha:0.1),
                AppColors.primaryLight.withValues(alpha:0.05),
              ],
            ),
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: AppColors.primary.withValues(alpha:0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.2),
                      borderRadius: AppRadius.md,
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Enable Passkey Login',
                          variant: TextVariant.titleMedium,
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodyMedium(
                          'Quick and secure sign-in with biometrics',
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppText.bodyMedium(
                'Passkeys let you sign in with your fingerprint, face, or screen lock instead of a password.',
                color: AppColors.onSurface,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppButton.primary(
                onPressed: state.isLoading
                    ? null
                    : () {
                        context.read<PasskeyBloc>().add(
                              const PasskeyAppendRequested(),
                            );
                      },
                loading: state.isLoading,
                fullWidth: true,
                leadingIcon: const Icon(Icons.add, size: 20),
                child: AppText.bodyMedium('Add Passkey', color: AppColors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
