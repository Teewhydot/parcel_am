import '../../../../core/bloc/base/base_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../domain/repositories/totp_repository.dart';
import '../../domain/usecases/totp_usecase.dart';
import 'totp_data.dart';

/// Cubit for managing TOTP 2FA state
class TotpCubit extends BaseCubit<BaseState<TotpData>> {
  final TotpUseCase _totpUseCase;

  TotpCubit({required TotpUseCase totpUseCase})
      : _totpUseCase = totpUseCase,
        super(const InitialState<TotpData>());

  /// Get current data or default
  TotpData get _currentData => state.data ?? const TotpData();

  /// Load current 2FA settings for user
  Future<void> loadSettings(String userId) async {
    emit(const LoadingState<TotpData>(message: 'Loading 2FA settings...'));

    final result = await _totpUseCase.getSettings(userId);

    result.fold(
      (failure) {
        // Settings don't exist = 2FA not enabled
        emit(LoadedState<TotpData>(
          data: const TotpData(isEnabled: false),
          lastUpdated: DateTime.now(),
        ));
      },
      (settings) async {
        // Also get remaining recovery codes count
        final codesResult =
            await _totpUseCase.getRemainingRecoveryCodesCount(userId);
        final remainingCodes = codesResult.fold((_) => 0, (count) => count);

        emit(LoadedState<TotpData>(
          data: TotpData(
            settings: settings,
            isEnabled: settings?.isEnabled ?? false,
            remainingRecoveryCodes: remainingCodes,
          ),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  /// Check if user has 2FA enabled
  Future<bool> is2FAEnabled(String userId) async {
    final result = await _totpUseCase.is2FAEnabled(userId);
    return result.fold((_) => false, (enabled) => enabled);
  }

  /// Start 2FA setup flow
  Future<void> startSetup(String userId, String email) async {
    emit(const LoadingState<TotpData>(message: 'Generating 2FA secret...'));

    final result = await _totpUseCase.initializeSetup(userId, email);

    result.fold(
      (failure) {
        emit(ErrorState<TotpData>(
          errorMessage: failure.failureMessage,
          errorCode: 'totp_setup_failed',
        ));
      },
      (setupResult) {
        emit(LoadedState<TotpData>(
          data: _currentData.copyWith(
            setupResult: setupResult,
            isInSetupMode: true,
            showRecoveryCodes: true,
          ),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  /// Verify code and complete setup
  Future<void> completeSetup(String userId, String code) async {
    emit(const LoadingState<TotpData>(message: 'Verifying code...'));

    final result = await _totpUseCase.completeSetup(userId, code);

    result.fold(
      (failure) {
        emit(ErrorState<TotpData>(
          errorMessage: failure.failureMessage,
          errorCode: 'totp_verification_failed',
        ));
        // Restore previous state for retry
        emit(LoadedState<TotpData>(
          data: _currentData.copyWith(
            errorMessage: failure.failureMessage,
          ),
          lastUpdated: DateTime.now(),
        ));
      },
      (success) {
        emit(const SuccessState<TotpData>(
          successMessage: '2FA enabled successfully!',
        ));
        // Update state to reflect enabled 2FA
        emit(LoadedState<TotpData>(
          data: _currentData.clearSetup().copyWith(
                isEnabled: true,
                remainingRecoveryCodes: 8, // Fresh set of recovery codes
              ),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  /// Verify code for protected action (e.g., escrow release)
  /// Returns true if verification succeeded
  Future<bool> verifyForAction(String userId, String code) async {
    emit(const LoadingState<TotpData>(message: 'Verifying...'));

    final result = await _totpUseCase.verify(userId, code);

    return result.fold(
      (failure) {
        emit(ErrorState<TotpData>(
          errorMessage: failure.failureMessage,
          errorCode: 'totp_verification_failed',
        ));
        emit(LoadedState<TotpData>(
          data: _currentData.copyWith(
            verificationSuccess: false,
            errorMessage: failure.failureMessage,
          ),
          lastUpdated: DateTime.now(),
        ));
        return false;
      },
      (verificationResult) {
        emit(const SuccessState<TotpData>(
          successMessage: 'Verification successful!',
        ));
        emit(LoadedState<TotpData>(
          data: _currentData.copyWith(
            verificationSuccess: true,
            errorMessage: null,
          ),
          lastUpdated: DateTime.now(),
        ));
        return verificationResult.isValid;
      },
    );
  }

  /// Verify with recovery code
  Future<bool> verifyWithRecoveryCode(String userId, String code) async {
    emit(const LoadingState<TotpData>(message: 'Verifying recovery code...'));

    final result = await _totpUseCase.verifyWithRecoveryCode(userId, code);

    return result.fold(
      (failure) {
        emit(ErrorState<TotpData>(
          errorMessage: failure.failureMessage,
          errorCode: 'recovery_code_failed',
        ));
        emit(LoadedState<TotpData>(
          data: _currentData.copyWith(
            verificationSuccess: false,
            errorMessage: failure.failureMessage,
          ),
          lastUpdated: DateTime.now(),
        ));
        return false;
      },
      (verificationResult) {
        emit(const SuccessState<TotpData>(
          successMessage: 'Recovery code accepted!',
        ));
        emit(LoadedState<TotpData>(
          data: _currentData.copyWith(
            verificationSuccess: true,
            remainingRecoveryCodes:
                verificationResult.remainingRecoveryCodes ?? 0,
            errorMessage: null,
          ),
          lastUpdated: DateTime.now(),
        ));
        return verificationResult.isValid;
      },
    );
  }

  /// Disable 2FA (requires verification first)
  Future<void> disable2FA(String userId) async {
    emit(const LoadingState<TotpData>(message: 'Disabling 2FA...'));

    final result = await _totpUseCase.disable2FA(userId);

    result.fold(
      (failure) {
        emit(ErrorState<TotpData>(
          errorMessage: failure.failureMessage,
          errorCode: 'totp_disable_failed',
        ));
      },
      (_) {
        emit(const SuccessState<TotpData>(
          successMessage: '2FA disabled successfully',
        ));
        emit(LoadedState<TotpData>(
          data: const TotpData(isEnabled: false),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  /// Regenerate recovery codes
  Future<void> regenerateRecoveryCodes(String userId) async {
    emit(const LoadingState<TotpData>(
      message: 'Generating new recovery codes...',
    ));

    final result = await _totpUseCase.regenerateRecoveryCodes(userId);

    result.fold(
      (failure) {
        emit(ErrorState<TotpData>(
          errorMessage: failure.failureMessage,
          errorCode: 'recovery_codes_failed',
        ));
      },
      (codes) {
        emit(const SuccessState<TotpData>(
          successMessage: 'New recovery codes generated!',
        ));
        emit(LoadedState<TotpData>(
          data: _currentData.copyWith(
            setupResult: TotpSetupResult(
              secretForDisplay: '',
              secret: '',
              qrCodeUri: '',
              recoveryCodes: codes,
            ),
            showRecoveryCodes: true,
            remainingRecoveryCodes: codes.length,
          ),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  /// Update verification code input
  void updateVerificationCode(String code) {
    emit(LoadedState<TotpData>(
      data: _currentData.copyWith(
        verificationCode: code,
        errorMessage: null,
      ),
      lastUpdated: DateTime.now(),
    ));
  }

  /// Cancel setup flow
  Future<void> cancelSetup(String userId) async {
    await _totpUseCase.cancelSetup(userId);
    emit(LoadedState<TotpData>(
      data: _currentData.clearSetup(),
      lastUpdated: DateTime.now(),
    ));
  }

  /// Hide recovery codes after user acknowledges them
  void hideRecoveryCodes() {
    emit(LoadedState<TotpData>(
      data: _currentData.copyWith(showRecoveryCodes: false),
      lastUpdated: DateTime.now(),
    ));
  }

  /// Clear verification state (for dialog reset)
  void clearVerification() {
    emit(LoadedState<TotpData>(
      data: _currentData.clearVerification(),
      lastUpdated: DateTime.now(),
    ));
  }

  /// Reset to initial state
  void reset() {
    emit(const InitialState<TotpData>());
  }
}
