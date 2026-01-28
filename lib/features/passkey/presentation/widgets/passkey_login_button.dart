import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/passkey_bloc.dart';
import '../bloc/passkey_data.dart';
import '../bloc/passkey_event.dart';

/// A button widget for passkey login
/// Only visible when passkeys are supported on the device
class PasskeyLoginButton extends StatelessWidget {
  const PasskeyLoginButton({
    super.key,
    this.onSuccess,
    this.onError,
  });

  final VoidCallback? onSuccess;
  final Function(String)? onError;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasskeyBloc, BaseState<PasskeyData>>(
      listener: (context, state) {
        if (state.isSuccess) {
          onSuccess?.call();
        } else if (state.isError) {
          onError?.call(state.errorMessage ?? 'Passkey authentication failed');
        }
      },
      builder: (context, state) {
        final passkeyData = state.data ?? const PasskeyData();

        // Only show if passkeys are supported
        if (!passkeyData.isSupported) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            AppSpacing.verticalSpacing(SpacingSize.md),
            _buildDivider(),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppButton.outline(
              onPressed: state.isLoading
                  ? null
                  : () {
                      context.read<PasskeyBloc>().add(
                            const PasskeySignInRequested(),
                          );
                    },
              fullWidth: true,
              loading: state.isLoading,
              borderRadius: AppRadius.md,
              leadingIcon: const Icon(Icons.fingerprint, size: 24),
              child: AppText(
                state.isLoading ? 'Authenticating...' : 'Sign in with Passkey',
                variant: TextVariant.bodyLarge,
                fontSize: AppFontSize.bodyLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.outline),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText(
            'or',
            variant: TextVariant.bodyMedium,
            fontSize: AppFontSize.bodyMedium,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.outline),
        ),
      ],
    );
  }
}
