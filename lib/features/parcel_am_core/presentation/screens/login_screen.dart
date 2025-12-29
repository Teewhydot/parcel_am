import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/core/widgets/app_scaffold.dart';
import 'package:parcel_am/features/passkey/presentation/bloc/passkey_bloc.dart';
import 'package:parcel_am/features/passkey/presentation/bloc/passkey_data.dart';
import 'package:parcel_am/features/passkey/presentation/bloc/passkey_event.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../bloc/auth/auth_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.isSignUp = false});

  final bool isSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _resetEmailController = TextEditingController();
  late TabController _tabController;
  bool _showPasswordReset = false;

  // Real-time validation states
  String? _emailError;
  String? _passwordError;
  String? _displayNameError;
  String? _resetEmailError;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  final bool _displayNameTouched = false;
  final bool _resetEmailTouched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['showSignIn'] == true) {
      _tabController.animateTo(0);
    }

    // Add listeners for real-time validation
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _displayNameController.addListener(_validateDisplayName);
    _resetEmailController.addListener(_validateResetEmail);

    // Check passkey support
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PasskeyBloc>().add(const PasskeyCheckSupport());
    });
  }

  void _validateEmail() {
    if (!_emailTouched) return;
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!_isValidEmail(email)) {
        _emailError = 'Please enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    if (!_passwordTouched) return;
    setState(() {
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        _passwordError = 'Password is required';
      } else if (password.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateDisplayName() {
    if (!_displayNameTouched) return;
    setState(() {
      final displayName = _displayNameController.text.trim();
      if (displayName.isEmpty) {
        _displayNameError = 'Name is required';
      } else {
        _displayNameError = null;
      }
    });
  }

  void _validateResetEmail() {
    if (!_resetEmailTouched) return;
    setState(() {
      final email = _resetEmailController.text.trim();
      if (email.isEmpty) {
        _resetEmailError = 'Email is required';
      } else if (!_isValidEmail(email)) {
        _resetEmailError = 'Please enter a valid email';
      } else {
        _resetEmailError = null;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _resetEmailController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginRequested(email: email, password: password),
        );
  }

  void _register() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: email,
            password: password,
            displayName: displayName,
          ),
        );
  }

  void _resetPassword() {
    final email = _resetEmailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _navigateToDashboard() {
    sl<NavigationService>().navigateAndReplace(Routes.home);
  }

  void _showError(String message) {
    context.showErrorMessage(message);
  }

  void _showSuccess(String message) {
    context.showSnackbar(
      message: message,
      color: AppColors.success,
    );
  }

  void _togglePasswordResetView() {
    setState(() {
      _showPasswordReset = !_showPasswordReset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthBloc, BaseState<AuthData>>(
      bloc: context.read<AuthBloc>(),
      showLoadingIndicator: true,
      onSuccess: (context, state) {
        _navigateToDashboard();
      },
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: AppSpacing.paddingLG,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton.text(
                      onPressed: () {
                        if (_showPasswordReset) {
                          _togglePasswordResetView();
                        } else {
                          sl<NavigationService>().goBack();
                        }
                      },
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                    AppText.titleMedium(
                      _showPasswordReset ? 'Reset Password' : 'Welcome Back',
                      fontWeight: FontWeight.w600,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.huge),
                  ],
                ),
              ),
              Padding(
                padding: AppSpacing.paddingLG,
                child: AppContainer(
                  height: 192,
                  variant: ContainerVariant.filled,
                  borderRadius: AppRadius.lg,
                  child: AppContainer(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lg,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AppContainer(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.black.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showPasswordReset
                                    ? Icons.lock_reset
                                    : Icons.email,
                                size: 48,
                                color: AppColors.white,
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.sm),
                              Padding(
                                padding: AppSpacing.paddingMD,
                                child: AppText.bodyMedium(
                                  _showPasswordReset
                                      ? 'Enter your email to receive a password reset link'
                                      : 'Secure access with your email and password',
                                  color: AppColors.white,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: _showPasswordReset
                      ? _buildPasswordResetForm()
                      : Column(
                          children: [
                            AppContainer(
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                automaticIndicatorColorAdjustment: true,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                labelColor: AppColors.white,
                                unselectedLabelColor: AppColors.black,
                                dividerColor: AppColors.transparent,
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Sign Up'),
                                ],
                              ),
                            ),
                            AppSpacing.verticalSpacing(SpacingSize.xl),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildSignInForm(),
                                  _buildSignUpForm()
                                ],
                              ),
                            ),
                            Padding(
                              padding: AppSpacing.paddingMD,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'By continuing, you agree to our ',
                                    ),
                                    TextSpan(
                                      text: 'Terms & Privacy Policy',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInput.email(
                controller: _emailController,
                label: 'Email',
                hintText: 'your.email@example.com',
                errorText: _emailError,
                enabled: !state.isLoading,
                onTap: () {
                  if (!_emailTouched) {
                    setState(() => _emailTouched = true);
                  }
                },
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput.password(
                controller: _passwordController,
                label: 'Password',
                hintText: '••••••••',
                errorText: _passwordError,
                enabled: !state.isLoading,
                onTap: () {
                  if (!_passwordTouched) {
                    setState(() => _passwordTouched = true);
                  }
                },
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton.text(
                  onPressed: state.isLoading ? null : _togglePasswordResetView,
                  size: ButtonSize.small,
                  child: AppText.bodySmall(
                    'Forgot Password?',
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppButton.primary(
                onPressed: state.isLoading ? null : _login,
                fullWidth: true,
                loading: state.isLoading,
                child: AppText.bodyLarge(
                  'Sign In',
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Passkey Login Option
              _buildPasskeyLoginButton(state),
            ],
          ),
        );
      },
    );
  }

  /// Build passkey login button if supported
  Widget _buildPasskeyLoginButton(BaseState<AuthData> authState) {
    return BlocConsumer<PasskeyBloc, BaseState<PasskeyData>>(
      listener: (context, passkeyState) {
        if (passkeyState.isSuccess) {
          _navigateToDashboard();
        } else if (passkeyState.isError) {
          _showError(passkeyState.errorMessage ?? 'Passkey authentication failed');
        }
      },
      builder: (context, passkeyState) {
        final passkeyData = passkeyState.data ?? const PasskeyData();

        // Only show if passkeys are supported
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
                passkeyState.isLoading ? 'Authenticating...' : 'Sign in with Passkey',
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignUpForm() {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInput(
                controller: _displayNameController,
                label: 'Display Name',
                hintText: 'John Doe',
                prefixIcon: const Icon(Icons.person_outline),
                enabled: !state.isLoading,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput.email(
                controller: _emailController,
                label: 'Email',
                hintText: 'your.email@example.com',
                enabled: !state.isLoading,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppInput.password(
                controller: _passwordController,
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
                onPressed: state.isLoading ? null : _register,
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

  Widget _buildPasswordResetForm() {
    return BlocConsumer<AuthBloc, BaseState<AuthData>>(
      listener: (context, state) {
        if (state is SuccessState) {
          _showSuccess(
            'Password reset email sent! Check your inbox.',
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _togglePasswordResetView();
              _resetEmailController.clear();
            }
          });
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInput.email(
                controller: _resetEmailController,
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
                onPressed: state.isLoading ? null : _resetPassword,
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
                  onPressed: state.isLoading ? null : _togglePasswordResetView,
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
