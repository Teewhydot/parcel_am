import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';

enum AuthStatus {
  initial,
  loading,
  phoneNumberEntered,
  otpSent,
  otpVerifying,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String phoneNumber;
  final String otp;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;
  final bool canResendOtp;
  final int resendCooldown;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.phoneNumber = '',
    this.otp = '',
    this.verificationId,
    this.resendToken,
    this.errorMessage,
    this.canResendOtp = false,
    this.resendCooldown = 0,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? phoneNumber,
    String? otp,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
    bool? canResendOtp,
    int? resendCooldown,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otp: otp ?? this.otp,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      errorMessage: errorMessage ?? this.errorMessage,
      canResendOtp: canResendOtp ?? this.canResendOtp,
      resendCooldown: resendCooldown ?? this.resendCooldown,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading || status == AuthStatus.otpVerifying;
  bool get hasError => status == AuthStatus.error && errorMessage != null;
  bool get isOtpSent => status == AuthStatus.otpSent;
  bool get isPhoneNumberValid => phoneNumber.isNotEmpty && phoneNumber.length >= 14; // +234 XXX XXX XXXX

  @override
  List<Object?> get props => [
        status,
        user,
        phoneNumber,
        otp,
        verificationId,
        resendToken,
        errorMessage,
        canResendOtp,
        resendCooldown,
      ];
}