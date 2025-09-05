import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/utils/phone_formatter.dart';
import 'package:parcel_am/core/widgets/app_scaffold.dart';
import 'package:sms_autofill/sms_autofill.dart';

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
    with SingleTickerProviderStateMixin, CodeAutoFill {
  final _phoneController = TextEditingController(text: '+234 ');
  final _otpController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['showSignIn'] == true) {
      _tabController.animateTo(0);
    }

    // Initialize SMS code listening
    SmsAutoFill().listenForCode();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tabController.dispose();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  @override
  void codeUpdated() {
    // Handle auto-detected SMS code
    if (code != null && code!.length == 6) {
      _otpController.text = code!;
      context.read<AuthBloc>().add(AuthOtpChanged(code!));

      // Auto-verify if conditions are met
      final state = context.read<AuthBloc>().state;
      if (state is DataState<AuthData> &&
          state.data != null &&
          state.data!.isOtpSent &&
          !state.isLoading) {
        _verifyOTP();
      }
    }
  }

  void _sendOTP() {
    final phoneNumber = _phoneController.text.trim();
    context.read<AuthBloc>().add(AuthSendOtpRequested(phoneNumber));
  }

  void _verifyOTP() {
    final state = context.read<AuthBloc>().state;
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit code');
      return;
    }

    if (!(state is DataState<AuthData> &&
        state.data != null &&
        state.data!.isOtpSent)) {
      _showError('Please request a new verification code');
      return;
    }

    context.read<AuthBloc>().add(
      AuthVerifyOtpRequested(
        phoneNumber: _phoneController.text.trim(),
        otp: otp,
      ),
    );
  }

  void _navigateToDashboard() {
    sl<NavigationService>().navigateAndReplace(Routes.dashboard);
  }

  void _resetOTPState() {
    _otpController.clear();
  }

  void _showError(String message) {
    context.showErrorMessage(message);
  }

  void _signUpWithPhone() {
    // Validate name fields for sign up
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    // Use the same OTP sending logic
    _sendOTP();
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
        } else if (state is DataState<AuthData> &&
            state.data != null &&
            state.data!.isOtpSent) {
          SmsAutoFill().listenForCode();
        }
      },
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
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
                    const SizedBox(width: 40), // Spacer
                  ],
                ),
              ),

              // Hero Image
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
                        // Background pattern/image placeholder
                        Positioned.fill(
                          child: AppContainer(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 48,
                                color: Colors.white,
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.sm),
                              Padding(
                                padding: AppSpacing.paddingMD,
                                child: AppText.bodyMedium(
                                  'Secure access with your Nigerian phone number',
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

              // Form Section
              Expanded(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    children: [
                      // Tabs
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

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildSignInForm(), _buildSignUpForm()],
                        ),
                      ),

                      // Terms
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
        final authData = state is DataState<AuthData> ? state.data : null;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authData == null || !authData.isOtpSent) ...[
                // Phone Number Input
                AppText.bodyMedium('Phone Number', fontWeight: FontWeight.w500),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !state.isLoading,
                  inputFormatters: [NigerianPhoneFormatter()],
                  decoration: InputDecoration(
                    hintText: '+234 801 234 5678',
                    prefixIcon: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text('🇳🇬', style: TextStyle(fontSize: 16)),
                      ),
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

                AppText.bodySmall(
                  'We\'ll send a verification code to this number',
                  color: Colors.grey,
                ),
              ] else ...[
                // OTP Input
                AppText.bodyMedium(
                  'Verification Code',
                  fontWeight: FontWeight.w500,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),

                AppText.bodySmall(
                  'Enter the 6-digit code sent to ${_phoneController.text}',
                  color: Colors.grey,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),

                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  enabled: !state.isLoading,
                  maxLength: 6,
                  inputFormatters: [OTPFormatter()],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '123456',
                    counterText: '',
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

                // Resend Code Button
                Center(
                  child: TextButton(
                    onPressed:
                        (authData?.resendCooldown ?? 0) > 0 || state.isLoading
                        ? null
                        : _sendOTP,
                    child: AppText.bodySmall(
                      (authData?.resendCooldown ?? 0) > 0
                          ? 'Resend code in ${authData?.resendCooldown ?? 0}s'
                          : 'Resend verification code',
                      color: (authData?.resendCooldown ?? 0) > 0
                          ? Colors.grey
                          : AppColors.primary,
                    ),
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.md),

                // Change Phone Number
                Center(
                  child: TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            _resetOTPState();
                            context.read<AuthBloc>().add(
                              AuthPhoneNumberChanged(_phoneController.text),
                            );
                          },
                    child: AppText.bodySmall(
                      'Change phone number',
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              AppSpacing.verticalSpacing(SpacingSize.xl),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : (authData != null && authData.isOtpSent
                            ? _verifyOTP
                            : _sendOTP),
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
                          authData != null && authData.isOtpSent
                              ? 'Verify Code'
                              : 'Send Verification Code',
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
        final authData = state is DataState<AuthData> ? state.data : null;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authData == null || !authData.isOtpSent) ...[
                // Name fields for new users
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

                // Phone Number Input
                AppText.bodyMedium('Phone Number', fontWeight: FontWeight.w500),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !state.isLoading,
                  inputFormatters: [NigerianPhoneFormatter()],
                  decoration: InputDecoration(
                    hintText: '+234 801 234 5678',
                    prefixIcon: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text('🇳🇬', style: TextStyle(fontSize: 16)),
                      ),
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

                AppText.bodySmall(
                  'We\'ll send a verification code to create your account',
                  color: Colors.grey,
                ),
              ] else ...[
                // Show user info summary during OTP verification
                AppContainer(
                  padding: AppSpacing.paddingMD,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodySmall(
                        'Creating account for:',
                        color: Colors.grey,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xs),
                      AppText.bodyMedium(
                        '${_firstNameController.text} ${_lastNameController.text}',
                        fontWeight: FontWeight.w500,
                      ),
                      AppText.bodySmall(
                        _phoneController.text,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.lg),

                // OTP Input (reuse the same OTP form as sign in)
                AppText.bodyMedium(
                  'Verification Code',
                  fontWeight: FontWeight.w500,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),

                AppText.bodySmall(
                  'Enter the 6-digit code sent to ${_phoneController.text}',
                  color: Colors.grey,
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),

                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  enabled: !state.isLoading,
                  maxLength: 6,
                  inputFormatters: [OTPFormatter()],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '123456',
                    counterText: '',
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

                // Resend Code Button
                Center(
                  child: TextButton(
                    onPressed:
                        (authData?.resendCooldown ?? 0) > 0 || state.isLoading
                        ? null
                        : _sendOTP,
                    child: AppText.bodySmall(
                      (authData?.resendCooldown ?? 0) > 0
                          ? 'Resend code in ${authData?.resendCooldown ?? 0}s'
                          : 'Resend verification code',
                      color: (authData?.resendCooldown ?? 0) > 0
                          ? Colors.grey
                          : AppColors.primary,
                    ),
                  ),
                ),

                AppSpacing.verticalSpacing(SpacingSize.md),

                // Change Phone Number
                Center(
                  child: TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            _resetOTPState();
                            context.read<AuthBloc>().add(
                              AuthPhoneNumberChanged(_phoneController.text),
                            );
                          },
                    child: AppText.bodySmall(
                      'Change details',
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              AppSpacing.verticalSpacing(SpacingSize.xl),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : (authData != null && authData.isOtpSent
                            ? _verifyOTP
                            : () => _signUpWithPhone()),
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
                          authData != null && authData.isOtpSent
                              ? 'Create Account'
                              : 'Send Verification Code',
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
}
