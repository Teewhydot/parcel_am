import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:parcel_am/core/bloc_manager/bloc_manager.dart';
import 'package:parcel_am/core/bloc_manager/bloc_manager_config.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_state.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';

/// Widget that demonstrates using AuthBloc with BlocManager
class AuthBlocManagerWidget extends StatelessWidget {
  final Widget child;
  final BlocManagerConfig? config;

  const AuthBlocManagerWidget({
    Key? key,
    required this.child,
    this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthBloc, AuthState>(
      config: config ?? BlocManagerConfig.development(
        getIt: GetIt.instance,
      ),
      create: (context) => GetIt.instance<AuthBloc>()..add(const AuthStarted()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Handle side effects here
          if (state.status == AuthStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          
          if (state.status == AuthStatus.authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully authenticated!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: child,
      ),
    );
  }
}

/// Enhanced auth screen that works with BlocManager
class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Phone number input
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixText: '+234 ',
                  ),
                  onChanged: (value) {
                    context.read<AuthBloc>().add(AuthPhoneNumberChanged(value));
                  },
                  enabled: state.status != AuthStatus.loading,
                ),
                const SizedBox(height: 16),
                
                // OTP input (only show when OTP is sent)
                if (state.status == AuthStatus.otpSent || 
                    state.status == AuthStatus.otpVerifying) ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      hintText: 'Enter 6-digit code',
                    ),
                    maxLength: 6,
                    onChanged: (value) {
                      context.read<AuthBloc>().add(AuthOtpChanged(value));
                      
                      // Auto-verify when 6 digits are entered
                      if (value.length == 6 && state.isOtpSent) {
                        context.read<AuthBloc>().add(
                          AuthVerifyOtpRequested(
                            phoneNumber: state.phoneNumber,
                            otp: value,
                          ),
                        );
                      }
                    },
                    enabled: state.status != AuthStatus.otpVerifying,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Action button
                ElevatedButton(
                  onPressed: _getButtonAction(context, state),
                  child: _getButtonChild(state),
                ),
                
                // Resend OTP button
                if (state.status == AuthStatus.otpSent) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: state.canResendOtp ? () {
                      context.read<AuthBloc>().add(
                        AuthResendOtpRequested(state.phoneNumber),
                      );
                    } : null,
                    child: Text(
                      state.canResendOtp 
                        ? 'Resend Code' 
                        : 'Resend in ${state.resendCooldown}s',
                    ),
                  ),
                ],
                
                // User info when authenticated
                if (state.status == AuthStatus.authenticated && state.user != null) ...[
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${state.user!.displayName}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text('Phone: ${state.user!.phoneNumber}'),
                          Text('UID: ${state.user!.uid}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(const AuthLogoutRequested());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // State restoration button
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthRestoreStateRequested());
                  },
                  child: const Text('Restore State'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  VoidCallback? _getButtonAction(BuildContext context, AuthState state) {
    switch (state.status) {
      case AuthStatus.initial:
      case AuthStatus.unauthenticated:
        return state.phoneNumber.isNotEmpty ? () {
          context.read<AuthBloc>().add(
            AuthSendOtpRequested(state.phoneNumber),
          );
        } : null;
      
      case AuthStatus.otpSent:
        return state.otp.length == 6 ? () {
          context.read<AuthBloc>().add(
            AuthVerifyOtpRequested(
              phoneNumber: state.phoneNumber,
              otp: state.otp,
            ),
          );
        } : null;
      
      case AuthStatus.loading:
      case AuthStatus.otpVerifying:
      case AuthStatus.authenticated:
      case AuthStatus.error:
        return null;
      
      case AuthStatus.phoneNumberEntered:
        return () {
          context.read<AuthBloc>().add(
            AuthSendOtpRequested(state.phoneNumber),
          );
        };
    }
  }

  Widget _getButtonChild(AuthState state) {
    switch (state.status) {
      case AuthStatus.initial:
      case AuthStatus.unauthenticated:
      case AuthStatus.phoneNumberEntered:
        return const Text('Send OTP');
      
      case AuthStatus.loading:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Sending...'),
          ],
        );
      
      case AuthStatus.otpSent:
        return const Text('Verify Code');
      
      case AuthStatus.otpVerifying:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Verifying...'),
          ],
        );
      
      case AuthStatus.authenticated:
        return const Text('Authenticated');
      
      case AuthStatus.error:
        return const Text('Retry');
    }
  }
}

/// Example usage widget
class AuthExampleApp extends StatelessWidget {
  const AuthExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth BlocManager Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthBlocManagerWidget(
        config: BlocManagerConfig.development(
          getIt: GetIt.instance,
        ),
        child: const AuthScreen(),
      ),
    );
  }
}