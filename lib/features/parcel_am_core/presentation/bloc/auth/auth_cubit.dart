import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/core/utils/logger.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/user_entity.dart';
import 'package:parcel_am/features/parcel_am_core/domain/usecases/auth_usecase.dart';
import 'package:parcel_am/features/passkey/domain/usecases/passkey_usecase.dart';
import 'package:parcel_am/features/kyc/domain/entities/kyc_status.dart';
import 'auth_data.dart';

class AuthCubit extends BaseCubit<BaseState<AuthData>> {
  final authUseCase = AuthUseCase();
  final passkeyUseCase = PasskeyUseCase();

  AuthCubit() : super(const InitialState<AuthData>());

  /// Stream for watching user data (KYC status updates) - use with StreamBuilder
  Stream<Either<Failure, UserEntity>> watchUserData(String userId) async* {
    try {
      yield* authUseCase.watchKycStatus(userId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  Future<void> checkCurrentUser() async {
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

  void updateEmail(String email) {
    final currentData = state.data ?? const AuthData();
    emit(
      LoadedState<AuthData>(
        data: currentData.copyWith(email: email),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void updatePassword(String password) {
    final currentData = state.data ?? const AuthData();
    emit(
      LoadedState<AuthData>(
        data: currentData.copyWith(password: password),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  Future<void> login(String email, String password) async {
    emit(const LoadingState<AuthData>(message: 'Logging in...'));

    final result = await authUseCase.login(email, password);

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
            data: const AuthData().copyWith(user: user, email: email),
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    emit(const LoadingState<AuthData>(message: 'Creating account...'));

    final result = await authUseCase.register(
      email: email,
      password: password,
      displayName: displayName,
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
            data: const AuthData().copyWith(user: user, email: email),
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> logout() async {
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
        emit(const SuccessState(successMessage: "Logout success"));
      },
    );
  }

  Future<void> updateUserProfile(String displayName) async {
    final currentData = state.data ?? const AuthData();
    if (currentData.user == null) return;

    emit(const LoadingState<AuthData>(message: 'Updating profile...'));

    final updatedUser = currentData.user!.copyWith(
      displayName: displayName,
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

  Future<void> updateUserProfileWithKyc({
    required String displayName,
    KycStatus? kycStatus,
    Map<String, dynamic>? additionalData,
  }) async {
    final currentData = state.data ?? const AuthData();
    if (currentData.user == null) return;

    emit(const LoadingState<AuthData>(message: 'Updating profile...'));

    final updatedUser = currentData.user!.copyWith(
      displayName: displayName,
      kycStatus: kycStatus,
      additionalData: additionalData,
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

  Future<void> resetPassword(String email) async {
    emit(const LoadingState<AuthData>(message: 'Sending reset email...'));

    final result = await authUseCase.resetPassword(email);

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

  void updateKycStatus(String kycStatus) {
    final currentData = state.data ?? const AuthData();
    if (currentData.user == null) return;

    final updatedUser = currentData.user!.copyWith(
      kycStatus: KycStatus.fromString(kycStatus),
    );

    emit(
      LoadedState<AuthData>(
        data: currentData.copyWith(user: updatedUser),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  Future<void> checkPasskeySupport() async {
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

  Future<void> signInWithPasskey() async {
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
        await _completePasskeySignIn(
          corbadoUserId: authResult.corbadoUserId,
          email: authResult.email,
          displayName: authResult.displayName,
        );
      },
    );
  }

  Future<void> _completePasskeySignIn({
    required String corbadoUserId,
    required String email,
    required String? displayName,
  }) async {
    final result = await authUseCase.getCurrentUser();

    await result.fold(
      (failure) async {
        Logger.logError('Firebase user lookup failed: ${failure.failureMessage}');
        emit(ErrorState<AuthData>(
          errorMessage: 'Unable to complete passkey authentication',
          errorCode: 'firebase_linking_failed',
        ));
      },
      (user) async {
        if (user != null) {
          emit(SuccessState<AuthData>(successMessage: 'Signed in with passkey!'));
          emit(LoadedState<AuthData>(
            data: const AuthData().copyWith(
              user: user,
              email: email,
              isPasskeySupported: true,
              hasPasskeys: true,
            ),
            lastUpdated: DateTime.now(),
          ));
          Logger.logSuccess('Passkey sign in completed for: ${user.displayName}');
        } else {
          emit(const ErrorState<AuthData>(
            errorMessage: 'No account found. Please sign in with email/password first.',
            errorCode: 'no_user_found',
          ));
        }
      },
    );
  }
}
