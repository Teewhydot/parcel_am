import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import 'auth_event.dart';
import 'auth_data.dart';

class AuthBloc extends BaseBloC<AuthEvent, BaseState<AuthData>> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  
  Timer? _resendTimer;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
  }) : super(const InitialState<AuthData>()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthEmailChanged>(_onEmailChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckAuthState>(_onCheckAuthState);
    on<AuthUserProfileUpdateRequested>(_onUserProfileUpdateRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
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

  void _onEmailChanged(AuthEmailChanged event, Emitter<BaseState<AuthData>> emit) {
    final currentData = _getCurrentAuthData();
    emit(LoadedState<AuthData>(
      data: currentData.copyWith(email: event.email),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onPasswordChanged(AuthPasswordChanged event, Emitter<BaseState<AuthData>> emit) {
    final currentData = _getCurrentAuthData();
    emit(LoadedState<AuthData>(
      data: currentData.copyWith(password: event.password),
      lastUpdated: DateTime.now(),
    ));
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
          data: const AuthData().copyWith(
            user: user,
            email: event.email,
          ),
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
          data: const AuthData().copyWith(
            user: user,
            email: event.email,
          ),
          lastUpdated: DateTime.now(),
        ));
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

    final updatedAdditionalData = event.additionalData != null
        ? {...currentData.user!.additionalData, ...event.additionalData!}
        : currentData.user!.additionalData;

    final updatedUser = currentData.user!.copyWith(
      displayName: event.displayName,
      email: event.email ?? currentData.user!.email,
      kycStatus: event.kycStatus ?? currentData.user!.kycStatus,
      additionalData: updatedAdditionalData,
    );

    emit(LoadedState<AuthData>(
      data: currentData.copyWith(user: updatedUser),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<BaseState<AuthData>> emit) async {
    emit(const LoadingState<AuthData>(message: 'Sending reset email...'));

    final result = await resetPasswordUseCase(event.email);

    result.fold(
      (failure) {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'password_reset_failed',
        ));
      },
      (_) {
        emit(const SuccessState<AuthData>(
          successMessage: 'Password reset email sent! Check your inbox.',
        ));
      },
    );
  }

  AuthData _getCurrentAuthData() {
    if (state is DataState<AuthData> && (state as DataState<AuthData>).data != null) {
      return (state as DataState<AuthData>).data!;
    }
    return const AuthData();
  }
}
