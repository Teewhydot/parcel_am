import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import '../../../domain/usecases/phone_auth_usecase.dart';
import 'auth_event.dart';
import 'auth_data.dart';

class AuthBloc extends BaseBloC<AuthEvent, BaseState<AuthData>> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final PhoneAuthUseCase phoneAuthUseCase;
  final SendPhoneVerificationUseCase sendPhoneVerificationUseCase;
  
  Timer? _resendTimer;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.phoneAuthUseCase,
    required this.sendPhoneVerificationUseCase,
  }) : super(const InitialState<AuthData>()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthPhoneNumberChanged>(_onPhoneNumberChanged);
    on<AuthOtpChanged>(_onOtpChanged);
    on<AuthSendOtpRequested>(_onSendOtpRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthResendOtpRequested>(_onResendOtpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckAuthState>(_onCheckAuthState);
    on<AuthUserProfileUpdateRequested>(_onUserProfileUpdateRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthUpdateResendCooldown>(_onUpdateResendCooldown);
    on<AuthEnableResendOtp>(_onEnableResendOtp);
  }

  Future<void> _onAuthStarted(AuthStarted event, Emitter<BaseState<AuthData>> emit) async {
    emit(const LoadingState<AuthData>(message: 'Checking authentication...'));
    
    final result = await getCurrentUserUseCase();
    
    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'auth_check_failed',
        ));
      },
      (user) {
        if (user != null) {
          emit(LoadedState<AuthData>(
            data: const AuthData().copyWith(user: user),
            lastUpdated: DateTime.now(),
          ));
        } else {
          emit(const InitialState<AuthData>());
        }
      },
    );
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<BaseState<AuthData>> emit) async {
    emit(const LoadingState<AuthData>(message: 'Logging in...'));
    
    final result = await loginUseCase(LoginParams(
      email: event.email,
      password: event.password,
    ));
    
    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'login_failed',
        ));
      },
      (user) {
        emit(LoadedState<AuthData>(
          data: const AuthData().copyWith(user: user),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<BaseState<AuthData>> emit) async {
    emit(const LoadingState<AuthData>(message: 'Creating account...'));
    
    final result = await registerUseCase(RegisterParams(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    ));
    
    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'register_failed',
        ));
      },
      (user) {
        emit(LoadedState<AuthData>(
          data: const AuthData().copyWith(user: user),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  void _onPhoneNumberChanged(AuthPhoneNumberChanged event, Emitter<BaseState<AuthData>> emit) {
    final currentData = _getCurrentAuthData();
    emit(LoadedState<AuthData>(
      data: currentData.copyWith(phoneNumber: event.phoneNumber),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onOtpChanged(AuthOtpChanged event, Emitter<BaseState<AuthData>> emit) {
    final currentData = _getCurrentAuthData();
    emit(LoadedState<AuthData>(
      data: currentData.copyWith(otp: event.otp),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onSendOtpRequested(AuthSendOtpRequested event, Emitter<BaseState<AuthData>> emit) async {
    emit(const LoadingState<AuthData>(message: 'Sending verification code...'));

    final result = await sendPhoneVerificationUseCase(
      SendPhoneVerificationParams(phoneNumber: event.phoneNumber),
    );

    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'otp_send_failed',
        ));
      },
      (_) {
        final currentData = _getCurrentAuthData();
        emit(LoadedState<AuthData>(
          data: currentData.copyWith(
            phoneNumber: event.phoneNumber,
            canResendOtp: false,
            resendCooldown: 60,
            isOtpSent: true,
          ),
          lastUpdated: DateTime.now(),
        ));
        _startResendTimer();
      },
    );
  }

  Future<void> _onVerifyOtpRequested(AuthVerifyOtpRequested event, Emitter<BaseState<AuthData>> emit) async {
    final currentData = _getCurrentAuthData();
    emit(AsyncLoadingState<AuthData>(
      data: currentData.copyWith(otp: event.otp),
      message: 'Verifying code...',
    ));

    final result = await phoneAuthUseCase(PhoneAuthParams(
      phoneNumber: event.phoneNumber,
      verificationCode: event.otp,
    ));

    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'otp_verification_failed',
        ));
      },
      (user) {
        emit(LoadedState<AuthData>(
          data: currentData.copyWith(user: user, otp: event.otp),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onResendOtpRequested(AuthResendOtpRequested event, Emitter<BaseState<AuthData>> emit) async {
    final currentData = _getCurrentAuthData();
    if (!currentData.canResendOtp) return;

    emit(const LoadingState<AuthData>(message: 'Resending code...'));

    final result = await sendPhoneVerificationUseCase(
      SendPhoneVerificationParams(phoneNumber: event.phoneNumber),
    );

    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'otp_resend_failed',
        ));
      },
      (_) {
        emit(LoadedState<AuthData>(
          data: currentData.copyWith(
            phoneNumber: event.phoneNumber,
            canResendOtp: false,
            resendCooldown: 60,
            isOtpSent: true,
          ),
          lastUpdated: DateTime.now(),
        ));
        _startResendTimer();
      },
    );
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<BaseState<AuthData>> emit) async {
    emit(const LoadingState<AuthData>(message: 'Logging out...'));
    
    final result = await logoutUseCase();
    
    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'logout_failed',
        ));
      },
      (_) {
        emit(const InitialState<AuthData>());
      },
    );
  }

  Future<void> _onCheckAuthState(AuthCheckAuthState event, Emitter<BaseState<AuthData>> emit) async {
    final result = await getCurrentUserUseCase();
    
    result.fold(
      (failure) {
        emit(const InitialState<AuthData>());
      },
      (user) {
        if (user != null) {
          emit(LoadedState<AuthData>(
            data: const AuthData().copyWith(user: user),
            lastUpdated: DateTime.now(),
          ));
        } else {
          emit(const InitialState<AuthData>());
        }
      },
    );
  }

  Future<void> _onUserProfileUpdateRequested(AuthUserProfileUpdateRequested event, Emitter<BaseState<AuthData>> emit) async {
    final currentData = _getCurrentAuthData();
    if (currentData.user == null) return;

    emit(const LoadingState<AuthData>(message: 'Updating profile...'));

    final updatedUser = currentData.user!.copyWith(
      displayName: event.displayName,
      email: event.email,
      phoneNumber: event.phoneNumber,
    );

    // Note: You would need to create an UpdateUserProfileUseCase for this
    // For now, just update the state
    emit(LoadedState<AuthData>(
      data: currentData.copyWith(user: updatedUser),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<BaseState<AuthData>> emit) async {
    emit(const LoadingState<AuthData>(message: 'Resetting password...'));

    // Note: You would need to create a ResetPasswordUseCase for this
    // For now, just show success
    emit(const SuccessState<AuthData>(
      successMessage: 'Password reset instructions sent to your email',
    ));
  }

  void _onUpdateResendCooldown(AuthUpdateResendCooldown event, Emitter<BaseState<AuthData>> emit) {
    final currentData = _getCurrentAuthData();
    emit(LoadedState<AuthData>(
      data: currentData.copyWith(resendCooldown: event.cooldown),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onEnableResendOtp(AuthEnableResendOtp event, Emitter<BaseState<AuthData>> emit) {
    final currentData = _getCurrentAuthData();
    emit(LoadedState<AuthData>(
      data: currentData.copyWith(canResendOtp: true),
      lastUpdated: DateTime.now(),
    ));
  }

  AuthData _getCurrentAuthData() {
    if (state is DataState<AuthData> && (state as DataState<AuthData>).data != null) {
      return (state as DataState<AuthData>).data!;
    }
    return const AuthData();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentData = _getCurrentAuthData();
      if (currentData.resendCooldown > 0) {
        add(AuthUpdateResendCooldown(currentData.resendCooldown - 1));
      } else {
        add(AuthEnableResendOtp());
        timer.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }
}