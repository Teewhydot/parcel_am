import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/helpers/user_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_data.dart';

class PasswordResetForm extends StatelessWidget {
  const PasswordResetForm({
    super.key,
    required this.resetEmailController,
    required this.onResetPassword,
    required this.onBackToSignIn,
    required this.onResetSuccess,
  });

  final TextEditingController resetEmailController;
  final VoidCallback onResetPassword;
  final VoidCallback onBackToSignIn;
  final VoidCallback onResetSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, BaseState<AuthData>>(
      listener: (context, state) {
        if (state is SuccessState) {
          context.showSnackbar(
            color: AppColors.primary,
            message: 'Password reset email sent successfully',
          );
          onResetSuccess();
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInput.email(
                controller: resetEmailController,
                label: 'Email',
                hintText: 'your.email@example.com',
                enabled: !state.isLoading,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodySmall(
                'We\'ll send you a link to reset your password',
                color: AppColors.textSecondary,
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              AppButton.primary(
                onPressed: state.isLoading ? null : onResetPassword,
                fullWidth: true,
                loading: state.isLoading,
                child: AppText.bodyLarge(
                  'Send Reset Link',
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              Center(
                child: AppButton.text(
                  onPressed: state.isLoading ? null : onBackToSignIn,
                  size: ButtonSize.small,
                  child: AppText.bodySmall(
                    'Back to Sign In',
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
