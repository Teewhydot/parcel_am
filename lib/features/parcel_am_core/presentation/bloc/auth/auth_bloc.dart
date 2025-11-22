import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/domain/entities/kyc_status.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/core/utils/logger.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/user_model.dart';
import 'package:parcel_am/features/parcel_am_core/domain/usecases/auth_usecase.dart';
import 'auth_event.dart';
import 'auth_data.dart';

class AuthBloc extends BaseBloC<AuthEvent, BaseState<AuthData>> {
  final authUseCase = AuthUseCase();

  AuthBloc() : super(const InitialState<AuthData>()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthEmailChanged>(_onEmailChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserProfileUpdateRequested>(_onUserProfileUpdateRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthKycStatusUpdated>(_onKycStatusUpdated);
  }

  Stream<Either<Failure, UserModel>> watchUserData(String userId) async* {
    try {
      yield* authUseCase.watchKycStatus(userId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    emit(const LoadingState<AuthData>(message: 'Checking current user...'));

    final result = await authUseCase.getCurrentUser();

    await result.fold(
      (failure) async {
        emit(const InitialState<AuthData>());
      },
      (user) async {
        if (user == null) {
          emit(
            const ErrorState<AuthData>(
              errorMessage: 'No user is currently signed in.',
              errorCode: 'no_user',
            ),
          );
          Logger.logError('No current user found.');
          return;
        }
        emit(
          LoadedState<AuthData>(
            data: const AuthData().copyWith(user: user),
            lastUpdated: DateTime.now(),
          ),
        );
        Logger.logSuccess('User loaded successfully: ${user.displayName}');
      },
    );
  }

  void _onEmailChanged(
    AuthEmailChanged event,
    Emitter<BaseState<AuthData>> emit,
  ) {
    final currentData = state.data ?? const AuthData();
    emit(
      LoadedState<AuthData>(
        data: currentData.copyWith(email: event.email),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void _onPasswordChanged(
    AuthPasswordChanged event,
    Emitter<BaseState<AuthData>> emit,
  ) {
    final currentData = state.data ?? const AuthData();
    emit(
      LoadedState<AuthData>(
        data: currentData.copyWith(password: event.password),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    emit(const LoadingState<AuthData>(message: 'Logging in...'));

    final result = await authUseCase.login(event.email, event.password);

    result.fold(
      (failure) {
        emit(
          ErrorState<AuthData>(
            errorMessage: failure.failureMessage,
            errorCode: 'login_failed',
          ),
        );
      },
      (user) {
        emit(SuccessState<AuthData>(successMessage: 'Login successful!'));
        emit(
          LoadedState<AuthData>(
            data: const AuthData().copyWith(user: user, email: event.email),
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    emit(const LoadingState<AuthData>(message: 'Creating account...'));

    final result = await authUseCase.register(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );

    result.fold(
      (failure) {
        emit(
          ErrorState<AuthData>(
            errorMessage: failure.failureMessage,
            errorCode: 'register_failed',
          ),
        );
      },
      (user) {
        emit(
          LoadedState<AuthData>(
            data: const AuthData().copyWith(user: user, email: event.email),
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    emit(const LoadingState<AuthData>(message: 'Logging out...'));

    final result = await authUseCase.logout();

    result.fold(
      (failure) {
        emit(
          ErrorState<AuthData>(
            errorMessage: failure.failureMessage,
            errorCode: 'logout_failed',
          ),
        );
      },
      (_) {
        emit(const InitialState<AuthData>());
      },
    );
  }

  Future<void> _onUserProfileUpdateRequested(
    AuthUserProfileUpdateRequested event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    final currentData = state.data ?? const AuthData();
    if (currentData.user == null) return;

    emit(const LoadingState<AuthData>(message: 'Updating profile...'));

    final updatedUser = currentData.user!.copyWith(
      displayName: event.displayName,
    );
    final result = await authUseCase.updateUserProfile(updatedUser);
    result.fold(
      (failure) {
        emit(
          ErrorState<AuthData>(
            errorMessage: failure.failureMessage,
            errorCode: 'profile_update_failed',
          ),
        );
      },
      (_) {
        emit(
          LoadedState<AuthData>(
            data: currentData.copyWith(user: updatedUser),
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    emit(const LoadingState<AuthData>(message: 'Sending reset email...'));

    final result = await authUseCase.resetPassword(event.email);

    result.fold(
      (failure) {
        emit(
          ErrorState<AuthData>(
            errorMessage: failure.failureMessage,
            errorCode: 'password_reset_failed',
          ),
        );
      },
      (_) {
        emit(
          const SuccessState<AuthData>(
            successMessage: 'Password reset email sent! Check your inbox.',
          ),
        );
      },
    );
  }

  Future<void> _onKycStatusUpdated(
    AuthKycStatusUpdated event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    final currentData = state.data ?? const AuthData();
    if (currentData.user == null) return;

    final updatedUser = currentData.user!.copyWith(
      kycStatus: KycStatus.fromString(event.kycStatus),
    );

    emit(
      LoadedState<AuthData>(
        data: currentData.copyWith(user: updatedUser),
        lastUpdated: DateTime.now(),
      ),
    );
  }
}
