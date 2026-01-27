import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/core/widgets/app_scaffold.dart';
import 'package:parcel_am/features/passkey/presentation/bloc/passkey_bloc.dart';
import 'package:parcel_am/features/passkey/presentation/bloc/passkey_event.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_data.dart';
import '../widgets/login/login_header.dart';
import '../widgets/login/auth_tab_bar.dart';
import '../widgets/login/sign_in_form.dart';
import '../widgets/login/sign_up_form.dart';
import '../widgets/login/password_reset_form.dart';
import '../widgets/login/terms_text.dart';

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

  String? _emailError;
  String? _passwordError;
  bool _emailTouched = false;
  bool _passwordTouched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['showSignIn'] == true) {
      _tabController.animateTo(0);
    }

    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);

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
      context.showErrorMessage('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      context.showErrorMessage('Please enter a valid email address');
      return;
    }

    context.read<AuthCubit>().login(email, password);
  }

  void _register() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      context.showErrorMessage('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      context.showErrorMessage('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      context.showErrorMessage('Password must be at least 6 characters');
      return;
    }

    context.read<AuthCubit>().register(
          email: email,
          password: password,
          displayName: displayName,
        );
  }

  void _resetPassword() {
    final email = _resetEmailController.text.trim();

    if (email.isEmpty) {
      context.showErrorMessage('Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      context.showErrorMessage('Please enter a valid email address');
      return;
    }

    context.read<AuthCubit>().resetPassword(email);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _navigateToDashboard() {
    sl<NavigationService>().navigateAndReplace(Routes.home);
  }

  void _togglePasswordResetView() {
    setState(() {
      _showPasswordReset = !_showPasswordReset;
    });
  }

  void _handleResetSuccess() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _togglePasswordResetView();
        _resetEmailController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthCubit, BaseState<AuthData>>(
      bloc: context.read<AuthCubit>(),
      showLoadingIndicator: true,
      onSuccess: (context, state) {
        _navigateToDashboard();
      },
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              LoginHeader(showPasswordReset: _showPasswordReset),
              Expanded(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: _showPasswordReset
                      ? PasswordResetForm(
                          resetEmailController: _resetEmailController,
                          onResetPassword: _resetPassword,
                          onBackToSignIn: _togglePasswordResetView,
                          onResetSuccess: _handleResetSuccess,
                        )
                      : Column(
                          children: [
                            AuthTabBar(tabController: _tabController),
                            AppSpacing.verticalSpacing(SpacingSize.xl),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  SignInForm(
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                    emailError: _emailError,
                                    passwordError: _passwordError,
                                    emailTouched: _emailTouched,
                                    passwordTouched: _passwordTouched,
                                    onEmailTouched: () =>
                                        setState(() => _emailTouched = true),
                                    onPasswordTouched: () =>
                                        setState(() => _passwordTouched = true),
                                    onForgotPassword: _togglePasswordResetView,
                                    onLogin: _login,
                                    onPasskeySuccess: _navigateToDashboard,
                                  ),
                                  SignUpForm(
                                    displayNameController:
                                        _displayNameController,
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                    onRegister: _register,
                                  ),
                                ],
                              ),
                            ),
                            const TermsText(),
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

  Widget _buildAppBar() {
    return Padding(
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
    );
  }
}
