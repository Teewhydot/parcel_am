import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        context.read<PasskeyBloc>().add(
                              const PasskeySignInRequested(),
                            );
                      },
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : const Icon(Icons.fingerprint, size: 24),
                label: AppText(
                  state.isLoading ? 'Authenticating...' : 'Sign in with Passkey',
                  variant: TextVariant.bodyLarge,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
            fontSize: 14,
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
