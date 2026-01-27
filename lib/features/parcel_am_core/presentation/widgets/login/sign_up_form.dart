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

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.onRegister,
  });

  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, BaseState<AuthData>>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInput(
                controller: displayNameController,
                label: 'Display Name',
                hintText: 'John Doe',
                prefixIcon: const Icon(Icons.person_outline),
                enabled: !state.isLoading,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput.email(
                controller: emailController,
                label: 'Email',
                hintText: 'your.email@example.com',
                enabled: !state.isLoading,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput.password(
                controller: passwordController,
                label: 'Password',
                hintText: '••••••••',
                enabled: !state.isLoading,
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              AppText.bodySmall(
                'Password must be at least 6 characters',
                color: AppColors.textSecondary,
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              AppButton.primary(
                onPressed: state.isLoading ? null : onRegister,
                fullWidth: true,
                loading: state.isLoading,
                child: AppText.bodyLarge(
                  'Create Account',
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
