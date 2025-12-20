import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/withdrawal_order_entity.dart';
import '../../../domain/repositories/withdrawal_repository.dart';
import 'withdrawal_event.dart';
import 'withdrawal_data.dart';

class WithdrawalBloc extends BaseBloC<WithdrawalEvent, BaseState<WithdrawalData>> {
  final WithdrawalRepository _repository;

  // Withdrawal limits in NGN
  static const double minWithdrawalAmount = 100.0;
  static const double maxWithdrawalAmount = 500000.0;

  WithdrawalBloc({
    required WithdrawalRepository repository,
  })  : _repository = repository,
        super(const InitialState<WithdrawalData>()) {
    on<WithdrawalAmountChanged>(_onAmountChanged);
    on<WithdrawalBankAccountSelected>(_onBankAccountSelected);
    on<WithdrawalInitiateRequested>(_onInitiateRequested);
    on<WithdrawalStatusWatchRequested>(_onStatusWatchRequested);
    on<WithdrawalRetryRequested>(_onRetryRequested);
    on<WithdrawalReset>(_onReset);
  }

  Future<void> _onAmountChanged(
    WithdrawalAmountChanged event,
    Emitter<BaseState<WithdrawalData>> emit,
  ) async {
    final currentData = state.data ?? const WithdrawalData();

    // Parse amount
    final amountText = event.amount.trim();
    if (amountText.isEmpty) {
      emit(LoadedState<WithdrawalData>(
        data: currentData.copyWith(clearAmount: true, clearAmountError: true),
        lastUpdated: DateTime.now(),
      ));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      emit(LoadedState<WithdrawalData>(
        data: currentData.copyWith(
          amountError: 'Invalid amount',
          clearAmount: true,
        ),
        lastUpdated: DateTime.now(),
      ));
      return;
    }

    // Validate amount
    String? error;
    if (amount < minWithdrawalAmount) {
      error = 'Minimum withdrawal is NGN ${minWithdrawalAmount.toStringAsFixed(0)}';
    } else if (amount > maxWithdrawalAmount) {
      error = 'Maximum withdrawal is NGN ${maxWithdrawalAmount.toStringAsFixed(0)}';
    }

    emit(LoadedState<WithdrawalData>(
      data: currentData.copyWith(
        amount: amount,
        amountError: error,
        clearAmountError: error == null,
      ),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onBankAccountSelected(
    WithdrawalBankAccountSelected event,
    Emitter<BaseState<WithdrawalData>> emit,
  ) async {
    final currentData = state.data ?? const WithdrawalData();

    emit(LoadedState<WithdrawalData>(
      data: currentData.copyWith(selectedBankAccount: event.bankAccount),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onInitiateRequested(
    WithdrawalInitiateRequested event,
    Emitter<BaseState<WithdrawalData>> emit,
  ) async {
    try {
      final currentData = state.data ?? const WithdrawalData();

      // Validate amount against available balance
      if (event.amount > event.availableBalance) {
        emit(AsyncErrorState<WithdrawalData>(
          errorMessage: 'Insufficient balance. Available: NGN ${event.availableBalance.toStringAsFixed(2)}',
          data: currentData,
        ));
        return;
      }

      emit(LoadedState<WithdrawalData>(
        data: currentData.copyWith(isInitiating: true),
        lastUpdated: DateTime.now(),
      ));

      // Generate withdrawal reference
      final withdrawalReference = _repository.generateWithdrawalReference();

      Logger.logBasic('Initiating withdrawal with reference: $withdrawalReference');

      // Initiate withdrawal
      final withdrawalOrder = await _repository.initiateWithdrawal(
        userId: event.userId,
        amount: event.amount,
        recipientCode: event.bankAccount.recipientCode,
        withdrawalReference: withdrawalReference,
        bankAccount: BankAccountInfo(
          id: event.bankAccount.id,
          accountNumber: event.bankAccount.accountNumber,
          accountName: event.bankAccount.accountName,
          bankCode: event.bankAccount.bankCode,
          bankName: event.bankAccount.bankName,
        ),
      );

      emit(LoadedState<WithdrawalData>(
        data: currentData.copyWith(
          withdrawalOrder: withdrawalOrder,
          isInitiating: false,
        ),
        lastUpdated: DateTime.now(),
      ));

      Logger.logSuccess('Withdrawal initiated successfully: ${withdrawalOrder.id}');

      // Start watching withdrawal status
      add(WithdrawalStatusWatchRequested(withdrawalId: withdrawalOrder.id));
    } catch (e) {
      Logger.logError('Error initiating withdrawal: $e');
      final currentData = state.data ?? const WithdrawalData();
      final updatedData = currentData.copyWith(isInitiating: false);
      emit(AsyncErrorState<WithdrawalData>(
        errorMessage: _getErrorMessage(e),
        data: updatedData,
      ));
    }
  }

  Future<void> _onStatusWatchRequested(
    WithdrawalStatusWatchRequested event,
    Emitter<BaseState<WithdrawalData>> emit,
  ) async {
    try {
      // Use emit.forEach for proper stream handling in bloc
      await emit.forEach<WithdrawalOrderEntity>(
        _repository.watchWithdrawalOrder(event.withdrawalId),
        onData: (withdrawalOrder) {
          final currentData = state.data ?? const WithdrawalData();
          Logger.logBasic('Withdrawal status updated: ${withdrawalOrder.status.name}');
          return LoadedState<WithdrawalData>(
            data: currentData.copyWith(withdrawalOrder: withdrawalOrder),
            lastUpdated: DateTime.now(),
          );
        },
        onError: (error, stackTrace) {
          Logger.logError('Error watching withdrawal status: $error');
          final currentData = state.data ?? const WithdrawalData();
          return AsyncErrorState<WithdrawalData>(
            errorMessage: 'Failed to get withdrawal status updates',
            data: currentData,
          );
        },
      );
    } catch (e) {
      Logger.logError('Error setting up withdrawal status watch: $e');
      final currentData = state.data ?? const WithdrawalData();
      emit(AsyncErrorState<WithdrawalData>(
        errorMessage: 'Failed to watch withdrawal status',
        data: currentData,
      ));
    }
  }

  Future<void> _onRetryRequested(
    WithdrawalRetryRequested event,
    Emitter<BaseState<WithdrawalData>> emit,
  ) async {
    // Reset state and set retry data
    final retryData = WithdrawalData(
      amount: event.amount,
      selectedBankAccount: event.bankAccount,
    );

    emit(LoadedState<WithdrawalData>(
      data: retryData,
      lastUpdated: DateTime.now(),
    ));

    Logger.logBasic('Withdrawal retry prepared with amount: ${event.amount}');
  }

  Future<void> _onReset(
    WithdrawalReset event,
    Emitter<BaseState<WithdrawalData>> emit,
  ) async {
    // Reset to initial state
    emit(const InitialState<WithdrawalData>());
    Logger.logBasic('Withdrawal state reset');
  }

  String _getErrorMessage(dynamic error) {
    final errorMsg = error.toString();

    if (errorMsg.contains('No internet') || errorMsg.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorMsg.contains('timeout') || errorMsg.contains('Timeout')) {
      return 'Request timeout. Please check withdrawal status.';
    }

    if (errorMsg.contains('Insufficient balance')) {
      return errorMsg.contains('Available:')
          ? errorMsg.substring(errorMsg.indexOf('Insufficient'))
          : 'Insufficient balance for this withdrawal';
    }

    if (errorMsg.contains('Minimum withdrawal')) {
      return 'Minimum withdrawal amount is NGN ${minWithdrawalAmount.toStringAsFixed(0)}';
    }

    if (errorMsg.contains('Maximum withdrawal')) {
      return 'Maximum withdrawal amount is NGN ${maxWithdrawalAmount.toStringAsFixed(0)}';
    }

    if (errorMsg.contains('User not authenticated')) {
      return 'Please login and try again';
    }

    // Extract error message if it's in Exception format
    if (errorMsg.startsWith('Exception: ')) {
      return errorMsg.substring(11);
    }

    return 'Failed to process withdrawal. Please try again.';
  }
}
