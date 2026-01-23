import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/repositories/bank_account_repository.dart';
import 'bank_account_event.dart';
import 'bank_account_data.dart';

class BankAccountBloc extends BaseBloC<BankAccountEvent, BaseState<BankAccountData>> {
  final BankAccountRepository _repository;

  BankAccountBloc({
    required BankAccountRepository repository,
  })  : _repository = repository,
        super(const InitialState<BankAccountData>()) {
    on<BankAccountLoadRequested>(_onLoadRequested);
    on<BankListLoadRequested>(_onBankListLoadRequested);
    on<BankAccountVerificationRequested>(_onVerificationRequested);
    on<BankAccountAddRequested>(_onAddRequested);
    on<BankAccountDeleteRequested>(_onDeleteRequested);
    on<BankAccountRefreshRequested>(_onRefreshRequested);
    on<BankAccountVerificationCleared>(_onVerificationCleared);
  }

  Future<void> _onLoadRequested(
    BankAccountLoadRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    emit(const LoadingState<BankAccountData>());

    // Load both bank list and user bank accounts in parallel
    final bankListFuture = _repository.getBankList();
    final userAccountsFuture = _repository.getUserBankAccounts(event.userId);

    final bankListResult = await bankListFuture;
    final userAccountsResult = await userAccountsFuture;

    // Check if either failed
    if (bankListResult.isLeft() || userAccountsResult.isLeft()) {
      final errorMessage = bankListResult.fold(
        (failure) => failure.failureMessage,
        (_) => userAccountsResult.fold(
          (failure) => failure.failureMessage,
          (_) => 'Unknown error',
        ),
      );
      Logger.logError('Error loading bank accounts: $errorMessage');
      emit(ErrorState<BankAccountData>(errorMessage: errorMessage));
      return;
    }

    final bankList = bankListResult.getOrElse(() => []);
    final userAccounts = userAccountsResult.getOrElse(() => []);

    emit(LoadedState<BankAccountData>(
      data: BankAccountData(
        bankList: bankList,
        userBankAccounts: userAccounts,
      ),
      lastUpdated: DateTime.now(),
    ));

    Logger.logSuccess('Bank accounts loaded successfully');
  }

  Future<void> _onBankListLoadRequested(
    BankListLoadRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    final currentData = state.data ?? const BankAccountData();

    emit(LoadedState<BankAccountData>(
      data: currentData.copyWith(isVerifying: true),
      lastUpdated: DateTime.now(),
    ));

    final result = await _repository.getBankList();

    result.fold(
      (failure) {
        Logger.logError('Error loading bank list: ${failure.failureMessage}');
        emit(LoadedState<BankAccountData>(
          data: currentData.copyWith(isVerifying: false),
          lastUpdated: DateTime.now(),
        ));
        emit(AsyncErrorState<BankAccountData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (bankList) {
        emit(LoadedState<BankAccountData>(
          data: currentData.copyWith(
            bankList: bankList,
            isVerifying: false,
          ),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Bank list loaded successfully: ${bankList.length} banks');
      },
    );
  }

  Future<void> _onVerificationRequested(
    BankAccountVerificationRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    final currentData = state.data ?? const BankAccountData();

    emit(LoadedState<BankAccountData>(
      data: currentData.copyWith(isVerifying: true, clearVerification: true),
      lastUpdated: DateTime.now(),
    ));

    final result = await _repository.verifyBankAccount(
      accountNumber: event.accountNumber,
      bankCode: event.bankCode,
    );

    result.fold(
      (failure) {
        Logger.logError('Error verifying account: ${failure.failureMessage}');
        emit(LoadedState<BankAccountData>(
          data: currentData.copyWith(isVerifying: false),
          lastUpdated: DateTime.now(),
        ));
        emit(AsyncErrorState<BankAccountData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (verificationData) {
        final verificationResult = VerificationResult(
          accountName: verificationData['accountName'] as String,
          accountNumber: verificationData['accountNumber'] as String,
          bankCode: verificationData['bankCode'] as String,
        );

        emit(LoadedState<BankAccountData>(
          data: currentData.copyWith(
            verificationResult: verificationResult,
            isVerifying: false,
          ),
          lastUpdated: DateTime.now(),
        ));

        Logger.logSuccess('Account verified: ${verificationResult.accountName}');
      },
    );
  }

  Future<void> _onAddRequested(
    BankAccountAddRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    final currentData = state.data ?? const BankAccountData();

    // Check if max accounts reached
    if (currentData.hasReachedMaxAccounts) {
      emit(AsyncErrorState<BankAccountData>(
        errorMessage: 'Maximum of 5 bank accounts allowed',
        data: currentData,
      ));
      return;
    }

    emit(LoadedState<BankAccountData>(
      data: currentData.copyWith(isSaving: true),
      lastUpdated: DateTime.now(),
    ));

    final addResult = await _repository.addBankAccount(
      userId: event.userId,
      accountNumber: event.accountNumber,
      accountName: event.accountName,
      bankCode: event.bankCode,
      bankName: event.bankName,
    );

    await addResult.fold(
      (failure) async {
        Logger.logError('Error adding bank account: ${failure.failureMessage}');
        emit(LoadedState<BankAccountData>(
          data: currentData.copyWith(isSaving: false),
          lastUpdated: DateTime.now(),
        ));
        emit(AsyncErrorState<BankAccountData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (newAccount) async {
        // Refresh user bank accounts
        final refreshResult = await _repository.getUserBankAccounts(event.userId);

        refreshResult.fold(
          (failure) {
            // Account was added but refresh failed - still show success
            emit(LoadedState<BankAccountData>(
              data: currentData.copyWith(
                isSaving: false,
                clearVerification: true,
              ),
              lastUpdated: DateTime.now(),
            ));
          },
          (updatedAccounts) {
            emit(LoadedState<BankAccountData>(
              data: currentData.copyWith(
                userBankAccounts: updatedAccounts,
                isSaving: false,
                clearVerification: true,
              ),
              lastUpdated: DateTime.now(),
            ));
          },
        );

        Logger.logSuccess('Bank account added successfully: ${newAccount.accountName}');
      },
    );
  }

  Future<void> _onDeleteRequested(
    BankAccountDeleteRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    final currentData = state.data ?? const BankAccountData();

    final deleteResult = await _repository.deleteBankAccount(
      userId: event.userId,
      accountId: event.accountId,
    );

    await deleteResult.fold(
      (failure) async {
        Logger.logError('Error deleting bank account: ${failure.failureMessage}');
        emit(AsyncErrorState<BankAccountData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (_) async {
        // Refresh user bank accounts
        final refreshResult = await _repository.getUserBankAccounts(event.userId);

        refreshResult.fold(
          (failure) {
            // Delete succeeded but refresh failed
            Logger.logError('Error refreshing after delete: ${failure.failureMessage}');
          },
          (updatedAccounts) {
            emit(LoadedState<BankAccountData>(
              data: currentData.copyWith(
                userBankAccounts: updatedAccounts,
              ),
              lastUpdated: DateTime.now(),
            ));
          },
        );

        Logger.logSuccess('Bank account deleted successfully');
      },
    );
  }

  Future<void> _onRefreshRequested(
    BankAccountRefreshRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    final currentData = state.data ?? const BankAccountData();

    final result = await _repository.getUserBankAccounts(event.userId);

    result.fold(
      (failure) {
        Logger.logError('Error refreshing bank accounts: ${failure.failureMessage}');
        emit(AsyncErrorState<BankAccountData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (updatedAccounts) {
        emit(LoadedState<BankAccountData>(
          data: currentData.copyWith(
            userBankAccounts: updatedAccounts,
          ),
          lastUpdated: DateTime.now(),
        ));
        Logger.logSuccess('Bank accounts refreshed');
      },
    );
  }

  Future<void> _onVerificationCleared(
    BankAccountVerificationCleared event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    final currentData = state.data ?? const BankAccountData();
    emit(LoadedState<BankAccountData>(
      data: currentData.copyWith(clearVerification: true),
      lastUpdated: DateTime.now(),
    ));
  }
}
