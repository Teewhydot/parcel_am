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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_container.dart';
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
  bool _obscurePassword = true;
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
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: AppSpacing.paddingLG,
                child: AppContainer(
                  height: 192,
                  variant: ContainerVariant.filled,
                  borderRadius: BorderRadius.circular(16),
                  child: AppContainer(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
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
                              color: Colors.black.withValues(alpha: 0.1),
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
                                color: Colors.white,
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.sm),
                              Padding(
                                padding: AppSpacing.paddingMD,
                                child: AppText.bodyMedium(
                                  _showPasswordReset
                                      ? 'Enter your email to receive a password reset link'
                                      : 'Secure access with your email and password',
                                  color: Colors.white,
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
                                color: Colors.grey.withValues(alpha: 0.1),
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
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.black,
                                dividerColor: Colors.transparent,
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
                                    color: Colors.grey,
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
              AppText.bodyMedium('Email', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !state.isLoading,
                onTap: () {
                  if (!_emailTouched) {
                    setState(() => _emailTouched = true);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyMedium('Password', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !state.isLoading,
                onTap: () {
                  if (!_passwordTouched) {
                    setState(() => _passwordTouched = true);
                  }
                },
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: state.isLoading ? null : _togglePasswordResetView,
                  child: AppText.bodySmall(
                    'Forgot Password?',
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : AppText.bodyLarge(
                          'Sign In',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
                  child: AppText.bodySmall('or', color: Colors.grey),
                ),
                const Expanded(child: Divider(color: AppColors.outline)),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<PasskeyBloc>().add(
                              const PasskeySignInRequested(),
                            );
                      },
                icon: passkeyState.isLoading
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
                label: AppText.bodyLarge(
                  passkeyState.isLoading ? 'Authenticating...' : 'Sign in with Passkey',
                  color: AppColors.primary,
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

  Widget _buildSignUpForm() {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium('Display Name', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _displayNameController,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText: 'John Doe',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyMedium('Email', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyMedium('Password', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              AppText.bodySmall(
                'Password must be at least 6 characters',
                color: Colors.grey,
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : AppText.bodyLarge(
                          'Create Account',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
              AppText.bodyMedium('Email', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _resetEmailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodySmall(
                'We\'ll send you a link to reset your password',
                color: Colors.grey,
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : AppText.bodyLarge(
                          'Send Reset Link',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              Center(
                child: TextButton(
                  onPressed: state.isLoading ? null : _togglePasswordResetView,
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
