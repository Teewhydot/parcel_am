import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_data.dart';
import 'passkey_login_button.dart';

class SignInForm extends StatelessWidget {
  const SignInForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.emailError,
    required this.passwordError,
    required this.emailTouched,
    required this.passwordTouched,
    required this.onEmailTouched,
    required this.onPasswordTouched,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onPasskeySuccess,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? emailError;
  final String? passwordError;
  final bool emailTouched;
  final bool passwordTouched;
  final VoidCallback onEmailTouched;
  final VoidCallback onPasswordTouched;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final VoidCallback onPasskeySuccess;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, BaseState<AuthData>>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInput.email(
                controller: emailController,
                label: 'Email',
                hintText: 'your.email@example.com',
                errorText: emailError,
                enabled: !state.isLoading,
                onTap: () {
                  if (!emailTouched) {
                    onEmailTouched();
                  }
                },
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput.password(
                controller: passwordController,
                label: 'Password',
                hintText: '••••••••',
                errorText: passwordError,
                enabled: !state.isLoading,
                onTap: () {
                  if (!passwordTouched) {
                    onPasswordTouched();
                  }
                },
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton.text(
                  onPressed: state.isLoading ? null : onForgotPassword,
                  size: ButtonSize.small,
                  child: AppText.bodySmall(
                    'Forgot Password?',
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppButton.primary(
                onPressed: state.isLoading ? null : onLogin,
                fullWidth: true,
                loading: state.isLoading,
                child: AppText.bodyLarge(
                  'Sign In',
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PasskeyLoginButton(
                authState: state,
                onSuccess: onPasskeySuccess,
              ),
            ],
          ),
        );
      },
    );
  }
}
