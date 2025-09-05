import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';

/// Data class to hold authentication-specific properties
class AuthData extends Equatable {
  final UserEntity? user;
  final String phoneNumber;
  final String otp;
  final String? verificationId;
  final int? resendToken;
  final bool canResendOtp;
  final int resendCooldown;
  final bool isOtpSent;

  const AuthData({
    this.user,
    this.phoneNumber = '',
    this.otp = '',
    this.verificationId,
    this.resendToken,
    this.canResendOtp = false,
    this.resendCooldown = 0,
    this.isOtpSent = false,
  });

  AuthData copyWith({
    UserEntity? user,
    String? phoneNumber,
    String? otp,
    String? verificationId,
    int? resendToken,
    bool? canResendOtp,
    int? resendCooldown,
    bool? isOtpSent,
  }) {
    return AuthData(
      user: user ?? this.user,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otp: otp ?? this.otp,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      canResendOtp: canResendOtp ?? this.canResendOtp,
      resendCooldown: resendCooldown ?? this.resendCooldown,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isPhoneNumberValid => phoneNumber.isNotEmpty && phoneNumber.length >= 14; // +234 XXX XXX XXXX

  @override
  List<Object?> get props => [
        user,
        phoneNumber,
        otp,
        verificationId,
        resendToken,
        canResendOtp,
        resendCooldown,
        isOtpSent,
      ];
}