import 'package:bloc/bloc.dart';
import '../../../../core/bloc/base/base_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/passkey_usecase.dart';
import 'passkey_event.dart';
import 'passkey_data.dart';

/// BLoC for managing passkey authentication state
class PasskeyBloc extends BaseBloC<PasskeyEvent, BaseState<PasskeyData>> {
  final PasskeyUseCase _passkeyUseCase;

  PasskeyBloc({PasskeyUseCase? passkeyUseCase})
      : _passkeyUseCase = passkeyUseCase ?? PasskeyUseCase(),
        super(const InitialState<PasskeyData>()) {
    on<PasskeyCheckSupport>(_onCheckSupport);
    on<PasskeySignUpRequested>(_onSignUpRequested);
    on<PasskeySignInRequested>(_onSignInRequested);
    on<PasskeyAppendRequested>(_onAppendRequested);
    on<PasskeyListRequested>(_onListRequested);
    on<PasskeyRemoveRequested>(_onRemoveRequested);
    on<PasskeySignOutRequested>(_onSignOutRequested);
    on<PasskeyStateReset>(_onStateReset);
  }

  Future<void> _onCheckSupport(
    PasskeyCheckSupport event,
    Emitter<BaseState<PasskeyData>> emit,
  ) async {
    emit(const LoadingState<PasskeyData>(message: 'Checking passkey support...'));

    final result = await _passkeyUseCase.isPasskeySupported();

    result.fold(
      (failure) {
        emit(LoadedState<PasskeyData>(
          data: const PasskeyData(isSupported: false),
          lastUpdated: DateTime.now(),
        ));
        Logger.logError('Passkey support check failed: ${failure.failureMessage}');
      },
      (isSupported) {
        emit(LoadedState<PasskeyData>(
          data: PasskeyData(isSupported: isSupported),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Passkey support: $isSupported');
      },
    );
  }

  Future<void> _onSignUpRequested(
    PasskeySignUpRequested event,
    Emitter<BaseState<PasskeyData>> emit,
  ) async {
    emit(const LoadingState<PasskeyData>(message: 'Creating passkey...'));

    final result = await _passkeyUseCase.signUpWithPasskey(event.email);

    result.fold(
      (failure) {
        emit(ErrorState<PasskeyData>(
          errorMessage: failure.failureMessage,
          errorCode: 'passkey_signup_failed',
        ));
        Logger.logError('Passkey signup failed: ${failure.failureMessage}');
      },
      (authResult) {
        final currentData = state.data ?? const PasskeyData();
        emit(SuccessState<PasskeyData>(
          successMessage: 'Passkey created successfully!',
        ));
        emit(LoadedState<PasskeyData>(
          data: currentData.copyWith(
            authResult: authResult,
            hasPasskeys: true,
            isSupported: true,
          ),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Passkey signup successful for: ${authResult.email}');
      },
    );
  }

  Future<void> _onSignInRequested(
    PasskeySignInRequested event,
    Emitter<BaseState<PasskeyData>> emit,
  ) async {
    emit(const LoadingState<PasskeyData>(message: 'Authenticating with passkey...'));

    final result = await _passkeyUseCase.signInWithPasskey();

    result.fold(
      (failure) {
        emit(ErrorState<PasskeyData>(
          errorMessage: failure.failureMessage,
          errorCode: 'passkey_signin_failed',
        ));
        Logger.logError('Passkey signin failed: ${failure.failureMessage}');
      },
      (authResult) {
        final currentData = state.data ?? const PasskeyData();
        emit(SuccessState<PasskeyData>(
          successMessage: 'Signed in with passkey!',
        ));
        emit(LoadedState<PasskeyData>(
          data: currentData.copyWith(
            authResult: authResult,
            isSupported: true,
          ),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Passkey signin successful for: ${authResult.email}');
      },
    );
  }

  Future<void> _onAppendRequested(
    PasskeyAppendRequested event,
    Emitter<BaseState<PasskeyData>> emit,
  ) async {
    emit(const LoadingState<PasskeyData>(message: 'Adding passkey...'));

    final result = await _passkeyUseCase.appendPasskey();

    result.fold(
      (failure) {
        emit(ErrorState<PasskeyData>(
          errorMessage: failure.failureMessage,
          errorCode: 'passkey_append_failed',
        ));
        Logger.logError('Passkey append failed: ${failure.failureMessage}');
      },
      (passkey) {
        final currentData = state.data ?? const PasskeyData();
        final updatedPasskeys = [...currentData.passkeys, passkey];
        emit(SuccessState<PasskeyData>(
          successMessage: 'Passkey added successfully!',
        ));
        emit(LoadedState<PasskeyData>(
          data: currentData.copyWith(
            passkeys: updatedPasskeys,
            hasPasskeys: true,
          ),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Passkey appended successfully');
      },
    );
  }

  Future<void> _onListRequested(
    PasskeyListRequested event,
    Emitter<BaseState<PasskeyData>> emit,
  ) async {
    emit(const LoadingState<PasskeyData>(message: 'Loading passkeys...'));

    final result = await _passkeyUseCase.getPasskeys();

    result.fold(
      (failure) {
        emit(ErrorState<PasskeyData>(
          errorMessage: failure.failureMessage,
          errorCode: 'passkey_list_failed',
        ));
        Logger.logError('Failed to load passkeys: ${failure.failureMessage}');
      },
      (passkeys) {
        final currentData = state.data ?? const PasskeyData();
        emit(LoadedState<PasskeyData>(
          data: currentData.copyWith(
            passkeys: passkeys,
            hasPasskeys: passkeys.isNotEmpty,
          ),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Loaded ${passkeys.length} passkeys');
      },
    );
  }

  Future<void> _onRemoveRequested(
    PasskeyRemoveRequested event,
    Emitter<BaseState<PasskeyData>> emit,
  ) async {
    emit(const LoadingState<PasskeyData>(message: 'Removing passkey...'));

    final result = await _passkeyUseCase.removePasskey(event.credentialId);

    result.fold(
      (failure) {
        emit(ErrorState<PasskeyData>(
          errorMessage: failure.failureMessage,
          errorCode: 'passkey_remove_failed',
        ));
        Logger.logError('Failed to remove passkey: ${failure.failureMessage}');
      },
      (_) {
        final currentData = state.data ?? const PasskeyData();
        final updatedPasskeys = currentData.passkeys
            .where((p) => p.credentialId != event.credentialId)
            .toList();
        emit(SuccessState<PasskeyData>(
          successMessage: 'Passkey removed successfully!',
        ));
        emit(LoadedState<PasskeyData>(
          data: currentData.copyWith(
            passkeys: updatedPasskeys,
            hasPasskeys: updatedPasskeys.isNotEmpty,
          ),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Passkey removed successfully');
      },
    );
  }

  Future<void> _onSignOutRequested(
    PasskeySignOutRequested event,
    Emitter<BaseState<PasskeyData>> emit,
  ) async {
    emit(const LoadingState<PasskeyData>(message: 'Signing out...'));

    final result = await _passkeyUseCase.signOut();

    result.fold(
      (failure) {
        emit(ErrorState<PasskeyData>(
          errorMessage: failure.failureMessage,
          errorCode: 'passkey_signout_failed',
        ));
      },
      (_) {
        emit(const SuccessState<PasskeyData>(
          successMessage: 'Signed out successfully!',
        ));
        emit(const InitialState<PasskeyData>());
      },
    );
  }

  void _onStateReset(
    PasskeyStateReset event,
    Emitter<BaseState<PasskeyData>> emit,
  ) {
    emit(const InitialState<PasskeyData>());
  }
}
