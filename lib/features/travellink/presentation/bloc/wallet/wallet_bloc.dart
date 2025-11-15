import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'wallet_event.dart';
import 'wallet_data.dart';
import '../../../domain/usecases/wallet_usecase.dart';

class WalletBloc extends BaseBloC<WalletEvent, BaseState<WalletData>> {
  Timer? _refreshTimer;
  StreamSubscription? _balanceSubscription;
  String? _currentUserId;
  String? _currentWalletId;
  final _walletUseCase = WalletUseCase();


  WalletBloc()  :
        super(const InitialState<WalletData>()) {
    on<WalletStarted>(_onStarted);
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletRefreshRequested>(_onRefreshRequested);
    on<WalletBalanceUpdated>(_onBalanceUpdated);
    on<WalletEscrowHoldRequested>(_onEscrowHoldRequested);
    on<WalletEscrowReleaseRequested>(_onEscrowReleaseRequested);
    on<WalletBalanceRefreshRequested>(_onBalanceRefreshRequested);
  }

  Future<void> _onStarted(
    WalletStarted event,
    Emitter<BaseState<WalletData>> emit,
  ) async {
    _currentUserId = event.userId;
    emit(const LoadingState<WalletData>());

    // First, get the wallet to store the wallet ID
    final walletResult = await _walletUseCase.getWallet(event.userId);
    walletResult.fold(
      (failure) {
        // Handle error silently or emit error state if needed
      },
      (wallet) {
        _currentWalletId = wallet.id;
      },
    );

    await _balanceSubscription?.cancel();
    _balanceSubscription = _walletUseCase.watchBalance(event.userId).listen(
      (walletEither) {
        walletEither.fold(
          (failure) {
            add(const WalletBalanceUpdated(
              availableBalance: 0.0,
              pendingBalance: 0.0,
            ));
          },
          (wallet) {
            _currentWalletId = wallet.id;
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

    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_currentUserId != null) {
          add(WalletRefreshRequested(_currentUserId!));
        }
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
    emit(AsyncLoadingState<WalletData>(data: currentData, isRefreshing: true));
    await _fetchWalletData(emit);
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

    if (currentData.availableBalance < event.amount) {
      emit(AsyncErrorState<WalletData>(
        errorMessage: 'Insufficient balance',
        data: currentData,
      ));
      return;
    }

    emit(AsyncLoadingState<WalletData>(data: currentData));

    if (_currentWalletId != null) {
      final result = await _walletUseCase.holdBalance(
        _currentWalletId!,
        event.amount,
        event.packageId,
      );

      result.fold(
        (failure) {
          emit(AsyncErrorState<WalletData>(
            errorMessage: failure.failureMessage,
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

    emit(AsyncLoadingState<WalletData>(data: currentData));

    if (_currentWalletId != null) {
      // Use pendingBalance as the amount to release
      // In a proper implementation, this should track held amounts per transaction
      final result = await _walletUseCase.releaseBalance(
        _currentWalletId!,
        currentData.pendingBalance,
        event.transactionId,
      );

      result.fold(
        (failure) {
          emit(AsyncErrorState<WalletData>(
            errorMessage: failure.failureMessage,
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
      await Future.delayed(const Duration(milliseconds: 500));

      final walletData = const WalletData(
        availableBalance: 50000.0,
        pendingBalance: 0.0,
        wallet: WalletInfo(recentTransactions: []),
      );

      emit(LoadedState<WalletData>(
        data: walletData,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(ErrorState<WalletData>(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _balanceSubscription?.cancel();
    return super.close();
  }
}
