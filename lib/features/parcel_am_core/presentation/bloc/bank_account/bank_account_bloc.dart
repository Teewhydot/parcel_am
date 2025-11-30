import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/bank_info_entity.dart';
import '../../../domain/entities/user_bank_account_entity.dart';
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
    try {
      emit(const LoadingState<BankAccountData>());

      // Load both bank list and user bank accounts in parallel
      final results = await Future.wait([
        _repository.getBankList(),
        _repository.getUserBankAccounts(event.userId),
      ]);

      final bankList = results[0] as List<BankInfoEntity>;
      final userAccounts = results[1] as List<UserBankAccountEntity>;

      emit(LoadedState<BankAccountData>(
        data: BankAccountData(
          bankList: bankList,
          userBankAccounts: userAccounts,
        ),
        lastUpdated: DateTime.now(),
      ));

      Logger.logSuccess('Bank accounts loaded successfully');
    } catch (e) {
      Logger.logError('Error loading bank accounts: $e');
      emit(ErrorState<BankAccountData>(
        errorMessage: _getErrorMessage(e),
      ));
    }
  }

  Future<void> _onBankListLoadRequested(
    BankListLoadRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    try {
      final currentData = state.data ?? const BankAccountData();

      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(isVerifying: true),
        lastUpdated: DateTime.now(),
      ));

      final bankList = await _repository.getBankList();

      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(
          bankList: bankList,
          isVerifying: false,
        ),
        lastUpdated: DateTime.now(),
      ));

      Logger.logSuccess('Bank list loaded successfully: ${bankList.length} banks');
    } catch (e) {
      Logger.logError('Error loading bank list: $e');
      final currentData = state.data ?? const BankAccountData();
      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(isVerifying: false),
        lastUpdated: DateTime.now(),
      ));
      emit(AsyncErrorState<BankAccountData>(
        errorMessage: _getErrorMessage(e),
        data: currentData,
      ));
    }
  }

  Future<void> _onVerificationRequested(
    BankAccountVerificationRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    try {
      final currentData = state.data ?? const BankAccountData();

      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(isVerifying: true, clearVerification: true),
        lastUpdated: DateTime.now(),
      ));

      final result = await _repository.verifyBankAccount(
        accountNumber: event.accountNumber,
        bankCode: event.bankCode,
      );

      final verificationResult = VerificationResult(
        accountName: result['accountName'] as String,
        accountNumber: result['accountNumber'] as String,
        bankCode: result['bankCode'] as String,
      );

      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(
          verificationResult: verificationResult,
          isVerifying: false,
        ),
        lastUpdated: DateTime.now(),
      ));

      Logger.logSuccess('Account verified: ${verificationResult.accountName}');
    } catch (e) {
      Logger.logError('Error verifying account: $e');
      final currentData = state.data ?? const BankAccountData();
      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(isVerifying: false),
        lastUpdated: DateTime.now(),
      ));
      emit(AsyncErrorState<BankAccountData>(
        errorMessage: _getErrorMessage(e),
        data: currentData,
      ));
    }
  }

  Future<void> _onAddRequested(
    BankAccountAddRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    try {
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

      final newAccount = await _repository.addBankAccount(
        userId: event.userId,
        accountNumber: event.accountNumber,
        accountName: event.accountName,
        bankCode: event.bankCode,
        bankName: event.bankName,
      );

      // Refresh user bank accounts
      final updatedAccounts = await _repository.getUserBankAccounts(event.userId);

      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(
          userBankAccounts: updatedAccounts,
          isSaving: false,
          clearVerification: true,
        ),
        lastUpdated: DateTime.now(),
      ));

      Logger.logSuccess('Bank account added successfully: ${newAccount.accountName}');
    } catch (e) {
      Logger.logError('Error adding bank account: $e');
      final currentData = state.data ?? const BankAccountData();
      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(isSaving: false),
        lastUpdated: DateTime.now(),
      ));
      emit(AsyncErrorState<BankAccountData>(
        errorMessage: _getErrorMessage(e),
        data: currentData,
      ));
    }
  }

  Future<void> _onDeleteRequested(
    BankAccountDeleteRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    try {
      final currentData = state.data ?? const BankAccountData();

      await _repository.deleteBankAccount(
        userId: event.userId,
        accountId: event.accountId,
      );

      // Refresh user bank accounts
      final updatedAccounts = await _repository.getUserBankAccounts(event.userId);

      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(
          userBankAccounts: updatedAccounts,
        ),
        lastUpdated: DateTime.now(),
      ));

      Logger.logSuccess('Bank account deleted successfully');
    } catch (e) {
      Logger.logError('Error deleting bank account: $e');
      final currentData = state.data ?? const BankAccountData();
      emit(AsyncErrorState<BankAccountData>(
        errorMessage: _getErrorMessage(e),
        data: currentData,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    BankAccountRefreshRequested event,
    Emitter<BaseState<BankAccountData>> emit,
  ) async {
    try {
      final currentData = state.data ?? const BankAccountData();

      // Refresh user bank accounts
      final updatedAccounts = await _repository.getUserBankAccounts(event.userId);

      emit(LoadedState<BankAccountData>(
        data: currentData.copyWith(
          userBankAccounts: updatedAccounts,
        ),
        lastUpdated: DateTime.now(),
      ));

      Logger.logSuccess('Bank accounts refreshed');
    } catch (e) {
      Logger.logError('Error refreshing bank accounts: $e');
      final currentData = state.data ?? const BankAccountData();
      emit(AsyncErrorState<BankAccountData>(
        errorMessage: _getErrorMessage(e),
        data: currentData,
      ));
    }
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

  String _getErrorMessage(dynamic error) {
    final errorMsg = error.toString();

    if (errorMsg.contains('No internet') || errorMsg.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorMsg.contains('Could not resolve') || errorMsg.contains('Invalid account')) {
      return 'Could not verify account. Please check account number and bank.';
    }

    if (errorMsg.contains('Maximum')) {
      return 'Maximum of 5 bank accounts allowed';
    }

    if (errorMsg.contains('10 digits')) {
      return 'Account number must be exactly 10 digits';
    }

    if (errorMsg.contains('select a bank')) {
      return 'Please select a bank';
    }

    // Extract error message if it's in Exception format
    if (errorMsg.startsWith('Exception: ')) {
      return errorMsg.substring(11);
    }

    return 'An error occurred. Please try again.';
  }
}
