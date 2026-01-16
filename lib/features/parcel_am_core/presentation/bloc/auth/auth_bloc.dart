import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/kyc/domain/entities/kyc_status.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/core/utils/logger.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/user_model.dart';
import 'package:parcel_am/features/parcel_am_core/domain/usecases/auth_usecase.dart';
import 'package:parcel_am/features/passkey/domain/usecases/passkey_usecase.dart';
import 'auth_event.dart';
import 'auth_data.dart';

class AuthBloc extends BaseBloC<AuthEvent, BaseState<AuthData>> {
  final authUseCase = AuthUseCase();
  final passkeyUseCase = PasskeyUseCase();

  // Cache for user data streams to prevent creating new streams on each call
  final Map<String, Stream<Either<Failure, UserModel>>> _userDataStreams = {};

  // Subscription to user data stream for realtime KYC updates
  StreamSubscription<Either<Failure, UserModel>>? _userDataSubscription;

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
    on<AuthPasskeyCheckSupport>(_onPasskeyCheckSupport);
    on<AuthPasskeySignInRequested>(_onPasskeySignInRequested);
    on<AuthPasskeySignInCompleted>(_onPasskeySignInCompleted);
  }


  /// Watch user data stream for realtime updates
  /// Returns a cached broadcast stream to ensure the same stream is reused
  /// across multiple widget rebuilds (fixes KYC realtime update issue)
  Stream<Either<Failure, UserModel>> watchUserData(String userId) {
    // Return cached stream if exists, otherwise create and cache new one
    return _userDataStreams.putIfAbsent(userId, () {
      // Create broadcast stream so multiple listeners can subscribe
      // and transform the async generator into a reusable stream
      return authUseCase.watchKycStatus(userId).asBroadcastStream();
    });
  }

  /// Clear cached streams (call on logout)
  void clearUserDataCache() {
    _userDataSubscription?.cancel();
    _userDataSubscription = null;
    _userDataStreams.clear();
  }

  /// Start listening to user data changes to keep state in sync with Firestore
  void _startUserDataListener(String userId) {
    _userDataSubscription?.cancel();
    _userDataSubscription = watchUserData(userId).listen((result) {
      result.fold(
        (failure) {
          Logger.logError('User data stream error: ${failure.failureMessage}');
        },
        (userData) {
          // Update state with fresh user data (including KYC status)
          final currentData = state.data ?? const AuthData();
          if (currentData.user?.kycStatus != userData.kycStatus) {
            Logger.logSuccess('KYC status updated: ${userData.kycStatus}');
            add(AuthKycStatusUpdated(userData.kycStatus.toJson()));
          }
        },
      );
    });
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
        // Start listening to user data changes for realtime KYC updates
        _startUserDataListener(user.uid);
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
        // Start listening to user data changes for realtime KYC updates
        _startUserDataListener(user.uid);
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
        // Start listening to user data changes for realtime KYC updates
        _startUserDataListener(user.uid);
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
        // Clear cached user data streams on logout
        clearUserDataCache();
        emit(const SuccessState(successMessage: "Logout success"));
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

  /// Check if passkeys are supported on this device
  Future<void> _onPasskeyCheckSupport(
    AuthPasskeyCheckSupport event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    final result = await passkeyUseCase.isPasskeySupported();

    result.fold(
      (failure) {
        Logger.logError('Passkey support check failed: ${failure.failureMessage}');
        final currentData = state.data ?? const AuthData();
        emit(LoadedState<AuthData>(
          data: currentData.copyWith(isPasskeySupported: false),
          lastUpdated: DateTime.now(),
        ));
      },
      (isSupported) {
        Logger.logSuccess('Passkey support: $isSupported');
        final currentData = state.data ?? const AuthData();
        emit(LoadedState<AuthData>(
          data: currentData.copyWith(isPasskeySupported: isSupported),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  /// Sign in using passkey
  Future<void> _onPasskeySignInRequested(
    AuthPasskeySignInRequested event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    emit(const LoadingState<AuthData>(message: 'Authenticating with passkey...'));

    final result = await passkeyUseCase.signInWithPasskey();

    await result.fold(
      (failure) async {
        emit(ErrorState<AuthData>(
          errorMessage: failure.failureMessage,
          errorCode: 'passkey_signin_failed',
        ));
        Logger.logError('Passkey sign in failed: ${failure.failureMessage}');
      },
      (authResult) async {
        // Passkey auth succeeded, now we need to link with Firebase user
        // Dispatch completed event to handle Firebase linking
        add(AuthPasskeySignInCompleted(
          corbadoUserId: authResult.corbadoUserId,
          email: authResult.email,
          displayName: authResult.displayName,
        ));
      },
    );
  }

  /// Handle passkey sign in completion - link with Firebase user
  Future<void> _onPasskeySignInCompleted(
    AuthPasskeySignInCompleted event,
    Emitter<BaseState<AuthData>> emit,
  ) async {
    // Try to get existing Firebase user by email
    final result = await authUseCase.getCurrentUser();

    await result.fold(
      (failure) async {
        // No existing Firebase user, create one or handle accordingly
        Logger.logError('Firebase user lookup failed: ${failure.failureMessage}');
        emit(ErrorState<AuthData>(
          errorMessage: 'Unable to complete passkey authentication',
          errorCode: 'firebase_linking_failed',
        ));
      },
      (user) async {
        if (user != null) {
          // Start listening to user data changes for realtime KYC updates
          _startUserDataListener(user.uid);
          // User exists, complete sign in
          emit(SuccessState<AuthData>(successMessage: 'Signed in with passkey!'));
          emit(LoadedState<AuthData>(
            data: const AuthData().copyWith(
              user: user,
              email: event.email,
              isPasskeySupported: true,
              hasPasskeys: true,
            ),
            lastUpdated: DateTime.now(),
          ));
          Logger.logSuccess('Passkey sign in completed for: ${user.displayName}');
        } else {
          // No user found - this shouldn't happen for passkey signin
          emit(const ErrorState<AuthData>(
            errorMessage: 'No account found. Please sign in with email/password first.',
            errorCode: 'no_user_found',
          ));
        }
      },
    );
  }
}
