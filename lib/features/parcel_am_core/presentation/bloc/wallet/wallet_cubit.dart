import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/core/services/connectivity_service.dart';
import 'package:parcel_am/core/utils/logger.dart';
import '../../../data/helpers/idempotency_helper.dart';
import '../../../domain/entities/wallet_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/value_objects/transaction_filter.dart';
import 'wallet_data.dart';
import '../../../domain/usecases/wallet_usecase.dart';

class WalletCubit extends BaseCubit<BaseState<WalletData>> {
  @visibleForTesting
  String? currentWalletId;
  String? _currentUserId;
  bool _isOnline = true;
  final WalletUseCase _walletUseCase;
  final ConnectivityService _connectivityService;

  WalletCubit({
    WalletUseCase? walletUseCase,
    ConnectivityService? connectivityService,
  })  : _walletUseCase = walletUseCase ?? WalletUseCase(),
        _connectivityService = connectivityService ?? ConnectivityService(),
        super(const InitialState<WalletData>()) {
    _connectivityService.startMonitoring();
    _connectivityService.onConnectivityChanged.listen((isOnline) {
      _isOnline = isOnline;
      // If we have current data, update it with new connectivity status
      final currentData = state.data;
      if (currentData != null) {
        emit(LoadedState<WalletData>(
          data: currentData,
          lastUpdated: DateTime.now(),
        ));
      }
    });
  }

  /// Stream for watching wallet balance - use with StreamBuilder
  Stream<Either<Failure, WalletEntity>> watchBalance(String userId) async* {
    try {
      yield* _walletUseCase.watchBalance(userId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  /// Stream for watching transactions - use with StreamBuilder
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions(
    String userId, {
    int limit = 20,
    TransactionFilter? filter,
  }) async* {
    try {
      yield* _walletUseCase.watchTransactions(
        userId,
        limit: limit,
        filter: filter,
      );
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  Future<void> start(String userId) async {
    _currentUserId = userId;
    emit(const LoadingState<WalletData>());

    // Try to get the wallet, create if it doesn't exist
    final walletResult = await _walletUseCase.getWallet(userId);
    await walletResult.fold(
      (failure) async {
        // If wallet not found, create it
        if (failure.failureMessage.contains('not found')) {
          final createResult = await _walletUseCase.createWallet(userId);
          createResult.fold(
            (createFailure) {
              emit(ErrorState<WalletData>(
                  errorMessage: createFailure.failureMessage));
            },
            (wallet) {
              currentWalletId = wallet.id;
              _emitWalletData(wallet);
            },
          );
        } else {
          emit(ErrorState<WalletData>(errorMessage: failure.failureMessage));
        }
      },
      (wallet) async {
        currentWalletId = wallet.id;
        _emitWalletData(wallet);
      },
    );
  }

  void _emitWalletData(WalletEntity wallet) {
    emit(LoadedState<WalletData>(
      data: WalletData(
        availableBalance: wallet.availableBalance,
        pendingBalance: wallet.heldBalance,
        wallet: WalletInfo(recentTransactions: const []),
      ),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> loadWallet() async {
    if (_currentUserId == null) {
      emit(const ErrorState<WalletData>(errorMessage: 'User ID not set'));
      return;
    }

    emit(const LoadingState<WalletData>());
    await _fetchWalletData();
  }

  Future<void> refresh() async {
    final currentData = state.data;
    if (currentData != null) {
      emit(AsyncLoadingState<WalletData>(data: currentData, isRefreshing: true));
      await _fetchWalletData();
    }
  }

  Future<void> holdEscrowBalance({
    required double amount,
    required String packageId,
  }) async {
    final currentData = state.data;
    if (currentData == null) {
      emit(const ErrorState<WalletData>(errorMessage: 'Wallet not loaded'));
      return;
    }

    // Check connectivity before proceeding
    if (!_isOnline) {
      emit(AsyncErrorState<WalletData>(
        errorMessage:
            'No internet connection. Please check your connection and try again.',
        data: currentData,
      ));
      return;
    }

    if (currentData.availableBalance < amount) {
      emit(AsyncErrorState<WalletData>(
        errorMessage: 'Insufficient balance',
        data: currentData,
      ));
      return;
    }

    emit(AsyncLoadingState<WalletData>(data: currentData));

    if (currentWalletId != null) {
      final idempotencyKey = IdempotencyHelper.generateTransactionId('hold');

      final result = await _walletUseCase.holdBalance(
        currentWalletId!,
        amount,
        packageId,
        idempotencyKey,
      );

      result.fold(
        (failure) {
          String errorMessage = failure.failureMessage;

          if (failure.failureMessage.contains('internet') ||
              failure.failureMessage.contains('connection')) {
            errorMessage =
                'No internet connection. Please check your connection and try again.';
          } else if (failure.failureMessage.contains('Insufficient')) {
            errorMessage =
                'Insufficient balance. Required: $amount, Available: ${currentData.availableBalance}';
          }

          emit(AsyncErrorState<WalletData>(
            errorMessage: errorMessage,
            data: currentData,
          ));
        },
        (wallet) {
          final updatedData = currentData.copyWith(
            availableBalance: wallet.availableBalance,
            pendingBalance: wallet.heldBalance,
          );
          emit(LoadedState<WalletData>(
            data: updatedData,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    } else {
      emit(const ErrorState<WalletData>(errorMessage: 'Wallet ID not set'));
    }
  }

  Future<void> releaseEscrowBalance({
    required double amount,
    required String transactionId,
  }) async {
    final currentData = state.data;
    if (currentData == null) {
      emit(const ErrorState<WalletData>(errorMessage: 'Wallet not loaded'));
      return;
    }

    if (!_isOnline) {
      emit(AsyncErrorState<WalletData>(
        errorMessage:
            'No internet connection. Please check your connection and try again.',
        data: currentData,
      ));
      return;
    }

    emit(AsyncLoadingState<WalletData>(data: currentData));

    if (currentWalletId != null) {
      final idempotencyKey = IdempotencyHelper.generateTransactionId('release');

      final result = await _walletUseCase.releaseBalance(
        currentWalletId!,
        amount,
        transactionId,
        idempotencyKey,
      );

      result.fold(
        (failure) {
          String errorMessage = failure.failureMessage;

          if (failure.failureMessage.contains('internet') ||
              failure.failureMessage.contains('connection')) {
            errorMessage =
                'No internet connection. Please check your connection and try again.';
          } else if (failure.failureMessage.contains('Insufficient held balance')) {
            errorMessage =
                'Insufficient held balance. Required: $amount, Available: ${currentData.pendingBalance}';
          }

          emit(AsyncErrorState<WalletData>(
            errorMessage: errorMessage,
            data: currentData,
          ));
        },
        (wallet) {
          final updatedData = currentData.copyWith(
            availableBalance: wallet.availableBalance,
            pendingBalance: wallet.heldBalance,
          );
          emit(LoadedState<WalletData>(
            data: updatedData,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    } else {
      emit(const ErrorState<WalletData>(errorMessage: 'Wallet ID not set'));
    }
  }

  Future<void> refreshBalance() async {
    final currentData = state.data;
    if (currentData != null) {
      emit(AsyncLoadingState<WalletData>(data: currentData));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(LoadedState<WalletData>(
        data: currentData,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> loadMoreTransactions() async {
    final currentData = state.data;
    final walletInfo = currentData?.wallet;

    if (currentData == null ||
        walletInfo == null ||
        !walletInfo.hasMoreTransactions ||
        walletInfo.isLoadingMore ||
        _currentUserId == null) {
      return;
    }

    // Set loading more state
    final loadingWallet = walletInfo.copyWith(isLoadingMore: true);
    emit(LoadedState<WalletData>(
      data: currentData.copyWith(wallet: loadingWallet),
      lastUpdated: DateTime.now(),
    ));

    // Fetch more transactions
    final result = await _walletUseCase.getTransactions(
      _currentUserId!,
      limit: 20,
      startAfter: walletInfo.lastTransactionDoc,
      filter: walletInfo.activeFilter,
    );

    result.fold(
      (failure) {
        final errorWallet = walletInfo.copyWith(isLoadingMore: false);
        emit(AsyncErrorState<WalletData>(
          errorMessage: failure.failureMessage,
          data: currentData.copyWith(wallet: errorWallet),
        ));
      },
      (newTransactions) {
        final allTransactions = [
          ...walletInfo.recentTransactions,
          ...newTransactions.map((t) => Transaction(
                id: t.id,
                type: t.type.name,
                amount: t.amount,
                date: t.timestamp,
                description: t.description ?? 'Transaction',
                status: t.status.name,
                referenceId: t.referenceId,
                metadata: t.metadata,
              )),
        ];

        final updatedWallet = walletInfo.copyWith(
          recentTransactions: allTransactions,
          isLoadingMore: false,
          hasMoreTransactions: newTransactions.length >= 20,
        );

        emit(LoadedState<WalletData>(
          data: currentData.copyWith(wallet: updatedWallet),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  void updateTransactionFilter(TransactionFilter filter) {
    final currentData = state.data;
    if (currentData == null || _currentUserId == null) return;

    final updatedWallet = currentData.wallet?.copyWith(
      activeFilter: filter,
      clearLastDoc: true,
    ) ?? WalletInfo(activeFilter: filter);

    emit(LoadedState<WalletData>(
      data: currentData.copyWith(wallet: updatedWallet),
      lastUpdated: DateTime.now(),
    ));
  }

  void updateTransactionSearch(String query) {
    final currentData = state.data;
    if (currentData == null || _currentUserId == null) return;

    final currentFilter = currentData.wallet?.activeFilter ?? const TransactionFilter.empty();
    final updatedFilter = currentFilter.copyWith(searchQuery: query);
    updateTransactionFilter(updatedFilter);
  }

  Future<void> _fetchWalletData() async {
    try {
      if (_currentUserId == null) {
        emit(const ErrorState<WalletData>(errorMessage: 'User ID not set'));
        return;
      }

      final walletResult = await _walletUseCase.getWallet(_currentUserId!);

      walletResult.fold(
        (failure) {
          emit(ErrorState<WalletData>(errorMessage: failure.failureMessage));
        },
        (wallet) async {
          currentWalletId = wallet.id;

          // Fetch recent transactions
          List<Transaction> recentTransactions = [];
          final transactionsResult = await _walletUseCase.getTransactions(
            _currentUserId!,
            limit: 10,
          );

          transactionsResult.fold(
            (failure) {
              Logger.logWarning(
                'Failed to fetch transactions: ${failure.failureMessage}',
                tag: 'WalletCubit',
              );
            },
            (transactions) {
              recentTransactions = transactions.map((t) => Transaction(
                id: t.id,
                type: t.type.name,
                amount: t.amount,
                date: t.timestamp,
                description: t.description ?? 'Transaction',
                status: t.status.name,
                referenceId: t.referenceId,
                metadata: t.metadata,
              )).toList();
            },
          );

          final walletData = WalletData(
            availableBalance: wallet.availableBalance,
            pendingBalance: wallet.heldBalance,
            wallet: WalletInfo(recentTransactions: recentTransactions),
          );

          emit(LoadedState<WalletData>(
            data: walletData,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      emit(ErrorState<WalletData>(errorMessage: e.toString()));
    }
  }

  /// Returns current online status for UI to check
  bool get isOnline => _isOnline;

  @override
  Future<void> close() {
    _connectivityService.dispose();
    return super.close();
  }
}
