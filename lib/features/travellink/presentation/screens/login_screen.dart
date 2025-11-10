import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/widgets/app_scaffold.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/error/error_handler.dart';
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
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  late TabController _tabController;
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _emailError;
  PasswordStrength _passwordStrength = PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['showSignIn'] == true) {
      _tabController.animateTo(0);
    }
    
    _passwordController.addListener(_validatePasswordStrength);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _validatePasswordStrength() {
    final password = _passwordController.text;
    
    if (password.isEmpty) {
      setState(() => _passwordStrength = PasswordStrength.none);
      return;
    }
    
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    setState(() {
      if (score <= 2) {
        _passwordStrength = PasswordStrength.weak;
      } else if (score <= 4) {
        _passwordStrength = PasswordStrength.medium;
      } else {
        _passwordStrength = PasswordStrength.strong;
      }
    });
  }

  void _signIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    if (!_validateEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    setState(() => _emailError = null);
    
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: email,
        password: password,
      ),
    );
  }

  void _signUp() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    if (!_validateEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    if (password.length < 8) {
      _showError('Password must be at least 8 characters long');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _emailError = null);
    
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        email: email,
        password: password,
        displayName: '$firstName $lastName',
      ),
    );
  }

  void _navigateToDashboard() {
    sl<NavigationService>().navigateAndReplace(Routes.dashboard);
  }

  void _showError(String message) {
    context.showErrorMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthBloc, BaseState<AuthData>>(
      bloc: context.read<AuthBloc>(),
      showLoadingIndicator: true,
      onSuccess: (context, state) {
        if (state is DataState<AuthData> &&
            state.data != null &&
            state.data!.user != null) {
          _navigateToDashboard();
        }
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
                      onPressed: () => sl<NavigationService>().goBack(),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                    AppText.titleMedium(
                      'Welcome Back',
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
                              const Icon(
                                Icons.email_outlined,
                                size: 48,
                                color: Colors.white,
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.sm),
                              Padding(
                                padding: AppSpacing.paddingMD,
                                child: AppText.bodyMedium(
                                  'Secure access with your email and password',
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
                  child: Column(
                    children: [
                      AppContainer(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TabBar(
                          controller: _tabController,
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
                          children: [_buildSignInForm(), _buildSignUpForm()],
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
              AppText.bodyMedium('Email Address', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !state.isLoading,
                onChanged: (value) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'example@email.com',
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

              AppSpacing.verticalSpacing(SpacingSize.lg),

              AppText.bodyMedium('Password', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
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

              AppSpacing.verticalSpacing(SpacingSize.md),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: state.isLoading ? null : () {},
                  child: AppText.bodySmall(
                    'Forgot Password?',
                    color: AppColors.primary,
                  ),
                ),
              ),

              AppSpacing.verticalSpacing(SpacingSize.xl),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _signIn,
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
            ],
          ),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyMedium(
                          'First Name',
                          fontWeight: FontWeight.w500,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        TextFormField(
                          controller: _firstNameController,
                          enabled: !state.isLoading,
                          decoration: InputDecoration(
                            hintText: 'John',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyMedium(
                          'Last Name',
                          fontWeight: FontWeight.w500,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        TextFormField(
                          controller: _lastNameController,
                          enabled: !state.isLoading,
                          decoration: InputDecoration(
                            hintText: 'Doe',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalSpacing(SpacingSize.lg),

              AppText.bodyMedium('Email Address', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !state.isLoading,
                onChanged: (value) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'example@email.com',
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

              AppSpacing.verticalSpacing(SpacingSize.lg),

              AppText.bodyMedium('Password', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText: 'Create a strong password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
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

              if (_passwordStrength != PasswordStrength.none) ...[
                AppSpacing.verticalSpacing(SpacingSize.sm),
                _buildPasswordStrengthIndicator(),
              ],

              AppSpacing.verticalSpacing(SpacingSize.lg),

              AppText.bodyMedium('Confirm Password', fontWeight: FontWeight.w500),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
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

              AppSpacing.verticalSpacing(SpacingSize.xl),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _signUp,
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

  Widget _buildPasswordStrengthIndicator() {
    Color strengthColor;
    String strengthText;
    double strengthValue;

    switch (_passwordStrength) {
      case PasswordStrength.weak:
        strengthColor = Colors.red;
        strengthText = 'Weak';
        strengthValue = 0.33;
        break;
      case PasswordStrength.medium:
        strengthColor = Colors.orange;
        strengthText = 'Medium';
        strengthValue = 0.66;
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.green;
        strengthText = 'Strong';
        strengthValue = 1.0;
        break;
      case PasswordStrength.none:
        return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strengthValue,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            AppSpacing.horizontalSpacing(SpacingSize.sm),
            AppText.bodySmall(
              strengthText,
              color: strengthColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.xs),
        AppText.bodySmall(
          'Use 8+ characters with uppercase, lowercase, numbers & symbols',
          color: Colors.grey,
        ),
      ],
    );
  }
}

enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
}
