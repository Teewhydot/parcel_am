import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/services/connectivity_service.dart';
import '../../../data/helpers/idempotency_helper.dart';
import 'wallet_event.dart';
import 'wallet_data.dart';
import '../../../domain/usecases/wallet_usecase.dart';

class WalletBloc extends BaseBloC<WalletEvent, BaseState<WalletData>> {
  Timer? _refreshTimer;
  StreamSubscription? _balanceSubscription;
  StreamSubscription? _connectivitySubscription;
  String? _currentUserId;
  @visibleForTesting
  String? currentWalletId;
  bool _isOnline = true;
  final WalletUseCase _walletUseCase;
  final ConnectivityService _connectivityService;

  WalletBloc({
    WalletUseCase? walletUseCase,
    ConnectivityService? connectivityService,
  })  : _walletUseCase = walletUseCase ?? WalletUseCase(),
        _connectivityService = connectivityService ?? ConnectivityService(),
        super(const InitialState<WalletData>()) {
    on<WalletStarted>(_onStarted);
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletRefreshRequested>(_onRefreshRequested);
    on<WalletBalanceUpdated>(_onBalanceUpdated);
    on<WalletEscrowHoldRequested>(_onEscrowHoldRequested);
    on<WalletEscrowReleaseRequested>(_onEscrowReleaseRequested);
    on<WalletBalanceRefreshRequested>(_onBalanceRefreshRequested);
    on<WalletConnectivityChanged>(_onConnectivityChanged);

    // Subscribe to connectivity changes
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      add(WalletConnectivityChanged(isOnline: isOnline));
    });

    // Start monitoring connectivity
    _connectivityService.startMonitoring();
  }

  Future<void> _onConnectivityChanged(
    WalletConnectivityChanged event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
    _isOnline = event.isOnline;

    // If we have current data, update it with new connectivity status
    final currentData = state.data;
    if (currentData != null) {
      // Emit the current data to trigger UI rebuild with connectivity state
      emit(LoadedState<WalletData>(
        data: currentData,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> _onStarted(
    WalletStarted event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
    _currentUserId = event.userId;
    emit(const LoadingState<WalletData>());

    // Try to get the wallet, create if it doesn't exist
    final walletResult = await _walletUseCase.getWallet(event.userId);
    await walletResult.fold(
      (failure) async {
        // If wallet not found, create it
        if (failure.failureMessage.contains('not found')) {
          final createResult = await _walletUseCase.createWallet(event.userId);
          createResult.fold(
            (createFailure) {
              // Failed to create wallet
              emit(ErrorState<WalletData>(
                  errorMessage: createFailure.failureMessage));
            },
            (wallet) {
              currentWalletId = wallet.id;
            },
          );
        }
      },
      (wallet) async {
        currentWalletId = wallet.id;
      },
    );

    // Set up stream subscription for real-time updates
    await _balanceSubscription?.cancel();
    _balanceSubscription = _walletUseCase.watchBalance(event.userId).listen(
      (walletEither) {
        walletEither.fold(
          (failure) {
            // Stream error - show zero balance
            add(const WalletBalanceUpdated(
              availableBalance: 0.0,
              pendingBalance: 0.0,
            ));
          },
          (wallet) {
            currentWalletId = wallet.id;
            add(WalletBalanceUpdated(
              availableBalance: wallet.availableBalance,
              pendingBalance: wallet.heldBalance,
            ));
          },
        );
      },
      onError: (error) {
        add(const WalletBalanceUpdated(
          availableBalance: 0.0,
          pendingBalance: 0.0,
        ));
      },
    );
  }

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
    emit(const LoadingState<WalletData>());
    await _fetchWalletData(emit);
  }

  Future<void> _onRefreshRequested(
    WalletRefreshRequested event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
    final currentData = state.data;
    if (currentData != null) {
      emit(AsyncLoadingState<WalletData>(data: currentData, isRefreshing: true));
      // The stream subscription will automatically update with latest data
      // Just emit the current data back after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      emit(LoadedState<WalletData>(
        data: currentData,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> _onBalanceUpdated(
    WalletBalanceUpdated event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
    final walletData = WalletData(
      availableBalance: event.availableBalance,
      pendingBalance: event.pendingBalance,
      wallet: const WalletInfo(recentTransactions: []),
    );

    emit(LoadedState<WalletData>(
      data: walletData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onEscrowHoldRequested(
    WalletEscrowHoldRequested event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
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

    if (currentData.availableBalance < event.amount) {
      emit(AsyncErrorState<WalletData>(
        errorMessage: 'Insufficient balance',
        data: currentData,
      ));
      return;
    }

    emit(AsyncLoadingState<WalletData>(data: currentData));

    if (currentWalletId != null) {
      // Generate idempotency key
      final idempotencyKey = IdempotencyHelper.generateTransactionId('hold');

      final result = await _walletUseCase.holdBalance(
        currentWalletId!,
        event.amount,
        event.packageId,
        idempotencyKey,
      );

      result.fold(
        (failure) {
          String errorMessage = failure.failureMessage;

          // Customize error message based on failure type
          if (failure.failureMessage.contains('internet') ||
              failure.failureMessage.contains('connection')) {
            errorMessage =
                'No internet connection. Please check your connection and try again.';
          } else if (failure.failureMessage.contains('Insufficient')) {
            errorMessage =
                'Insufficient balance. Required: ${event.amount}, Available: ${currentData.availableBalance}';
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

  Future<void> _onEscrowReleaseRequested(
    WalletEscrowReleaseRequested event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
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

    emit(AsyncLoadingState<WalletData>(data: currentData));

    if (currentWalletId != null) {
      // Generate idempotency key
      final idempotencyKey = IdempotencyHelper.generateTransactionId('release');

      // Use the amount from the event
      final result = await _walletUseCase.releaseBalance(
        currentWalletId!,
        event.amount,
        event.transactionId,
        idempotencyKey,
      );

      result.fold(
        (failure) {
          String errorMessage = failure.failureMessage;

          // Customize error message based on failure type
          if (failure.failureMessage.contains('internet') ||
              failure.failureMessage.contains('connection')) {
            errorMessage =
                'No internet connection. Please check your connection and try again.';
          } else if (failure.failureMessage.contains('Insufficient held balance')) {
            errorMessage =
                'Insufficient held balance. Required: ${event.amount}, Available: ${currentData.pendingBalance}';
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

  Future<void> _onBalanceRefreshRequested(
    WalletBalanceRefreshRequested event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
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

  Future<void> _fetchWalletData(Emitter<BaseState<WalletData>> emit) async {
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
        (wallet) {
          currentWalletId = wallet.id;
          final walletData = WalletData(
            availableBalance: wallet.availableBalance,
            pendingBalance: wallet.heldBalance,
            wallet: const WalletInfo(recentTransactions: []),
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
    _refreshTimer?.cancel();
    _balanceSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    return super.close();
  }
}
