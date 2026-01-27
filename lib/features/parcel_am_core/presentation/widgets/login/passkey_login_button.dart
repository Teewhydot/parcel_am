import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/helpers/user_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../passkey/presentation/bloc/passkey_bloc.dart';
import '../../../../passkey/presentation/bloc/passkey_data.dart';
import '../../../../passkey/presentation/bloc/passkey_event.dart';
import '../../bloc/auth/auth_data.dart';

class PasskeyLoginButton extends StatelessWidget {
  const PasskeyLoginButton({
    super.key,
    required this.authState,
    required this.onSuccess,
  });

  final BaseState<AuthData> authState;
  final VoidCallback onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasskeyBloc, BaseState<PasskeyData>>(
      listener: (context, passkeyState) {
        if (passkeyState.isSuccess) {
          onSuccess();
        } else if (passkeyState.isError) {
          context.showErrorMessage(
            passkeyState.errorMessage ?? 'Passkey authentication failed',
          );
        }
      },
      builder: (context, passkeyState) {
        final passkeyData = passkeyState.data ?? const PasskeyData();

        if (!passkeyData.isSupported) {
          return const SizedBox.shrink();
        }

        final isLoading = authState.isLoading || passkeyState.isLoading;

        return Column(
          children: [
            AppSpacing.verticalSpacing(SpacingSize.md),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppText.bodySmall('or', color: AppColors.textSecondary),
                ),
                const Expanded(child: Divider(color: AppColors.outline)),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppButton.outline(
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<PasskeyBloc>().add(
                            const PasskeySignInRequested(),
                          );
                    },
              fullWidth: true,
              loading: passkeyState.isLoading,
              leadingIcon: const Icon(Icons.fingerprint, size: 24),
              child: AppText.bodyLarge(
                passkeyState.isLoading
                    ? 'Authenticating...'
                    : 'Sign in with Passkey',
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}
