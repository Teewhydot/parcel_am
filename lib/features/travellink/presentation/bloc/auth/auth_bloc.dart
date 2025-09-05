import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import '../../../domain/usecases/phone_auth_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
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
  }) : super(const AuthState()) {
    
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

  Future<void> _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await getCurrentUserUseCase();
    
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.failureMessage,
        ));
      },
      (user) {
        if (user != null) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      },
    );
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await loginUseCase(LoginParams(
      email: event.email,
      password: event.password,
    ));
    
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.failureMessage,
        ));
      },
      (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await registerUseCase(RegisterParams(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    ));
    
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.failureMessage,
        ));
      },
      (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ));
      },
    );
  }

  void _onPhoneNumberChanged(AuthPhoneNumberChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      phoneNumber: event.phoneNumber,
      errorMessage: null,
    ));
  }

  void _onOtpChanged(AuthOtpChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      otp: event.otp,
      errorMessage: null,
    ));
  }

  Future<void> _onSendOtpRequested(AuthSendOtpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await sendPhoneVerificationUseCase(
      SendPhoneVerificationParams(phoneNumber: event.phoneNumber),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.failureMessage,
        ));
      },
      (_) {
        emit(state.copyWith(
          status: AuthStatus.otpSent,
          phoneNumber: event.phoneNumber,
          canResendOtp: false,
          resendCooldown: 60,
          errorMessage: null,
        ));
        _startResendTimer();
      },
    );
  }

  Future<void> _onVerifyOtpRequested(AuthVerifyOtpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.otpVerifying));

    final result = await phoneAuthUseCase(PhoneAuthParams(
      phoneNumber: event.phoneNumber,
      verificationCode: event.otp,
    ));

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.failureMessage,
        ));
      },
      (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onResendOtpRequested(AuthResendOtpRequested event, Emitter<AuthState> emit) async {
    if (!state.canResendOtp) return;

    emit(state.copyWith(
      status: AuthStatus.loading,
      canResendOtp: false,
    ));

    final result = await sendPhoneVerificationUseCase(
      SendPhoneVerificationParams(phoneNumber: event.phoneNumber),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.failureMessage,
          canResendOtp: true,
        ));
      },
      (_) {
        emit(state.copyWith(
          status: AuthStatus.otpSent,
          resendCooldown: 60,
          errorMessage: null,
        ));
        _startResendTimer();
      },
    );
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await logoutUseCase();
    
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.failureMessage,
        ));
      },
      (_) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          phoneNumber: '',
          otp: '',
          verificationId: null,
          resendToken: null,
          errorMessage: null,
          canResendOtp: false,
          resendCooldown: 0,
        ));
      },
    );
  }

  Future<void> _onCheckAuthState(AuthCheckAuthState event, Emitter<AuthState> emit) async {
    final result = await getCurrentUserUseCase();
    
    result.fold(
      (failure) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      },
      (user) {
        if (user != null) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      },
    );
  }

  Future<void> _onUserProfileUpdateRequested(AuthUserProfileUpdateRequested event, Emitter<AuthState> emit) async {
    if (state.user == null) return;

    emit(state.copyWith(status: AuthStatus.loading));

    final updatedUser = state.user!.copyWith(
      displayName: event.displayName,
      email: event.email,
      phoneNumber: event.phoneNumber,
    );

    // Note: You would need to create an UpdateUserProfileUseCase for this
    // For now, just update the state
    emit(state.copyWith(
      status: AuthStatus.authenticated,
      user: updatedUser,
    ));
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    // Note: You would need to create a ResetPasswordUseCase for this
    // For now, just show success
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    ));
  }

  void _onUpdateResendCooldown(AuthUpdateResendCooldown event, Emitter<AuthState> emit) {
    emit(state.copyWith(resendCooldown: event.cooldown));
  }

  void _onEnableResendOtp(AuthEnableResendOtp event, Emitter<AuthState> emit) {
    emit(state.copyWith(canResendOtp: true));
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCooldown > 0) {
        add(AuthUpdateResendCooldown(state.resendCooldown - 1));
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