import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'wallet_event.dart';
import 'wallet_data.dart';
import '../../../domain/usecases/watch_balance_usecase.dart';
import '../../../domain/usecases/hold_balance_for_escrow_usecase.dart';
import '../../../domain/usecases/release_escrow_balance_usecase.dart';

class WalletBloc extends BaseBloC<WalletEvent, BaseState<WalletData>> {
  final WatchBalanceUseCase? watchBalanceUseCase;
  final HoldBalanceForEscrowUseCase? holdBalanceUseCase;
  final ReleaseEscrowBalanceUseCase? releaseBalanceUseCase;

  Timer? _refreshTimer;
  StreamSubscription? _balanceSubscription;
  String? _currentUserId;

  WalletBloc({
    this.watchBalanceUseCase,
    this.holdBalanceUseCase,
    this.releaseBalanceUseCase,
  }) : super(const InitialState<WalletData>()) {
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

    if (watchBalanceUseCase != null) {
      await _balanceSubscription?.cancel();
      _balanceSubscription = watchBalanceUseCase!(event.userId).listen(
        (wallet) {
          add(WalletBalanceUpdated(
            availableBalance: wallet.availableBalance,
            pendingBalance: wallet.heldBalance,
          ));
        },
        onError: (error) {
          add(WalletBalanceUpdated(
            availableBalance: 0.0,
            pendingBalance: 0.0,
          ));
        },
      );
    } else {
      // Fallback to mock data if usecase not provided
      await _fetchWalletData(emit);
    }

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

    if (holdBalanceUseCase != null && _currentUserId != null) {
      final result = await holdBalanceUseCase!(HoldEscrowParams(
        userId: _currentUserId!,
        amount: event.amount,
        orderId: event.packageId,
      ));

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
      // Fallback to mock behavior
      await Future.delayed(const Duration(seconds: 2));
      final updatedData = currentData.copyWith(
        availableBalance: currentData.availableBalance - event.amount,
        pendingBalance: currentData.pendingBalance + event.amount,
      );
      emit(LoadedState<WalletData>(
        data: updatedData,
        lastUpdated: DateTime.now(),
      ));
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

    if (releaseBalanceUseCase != null && _currentUserId != null) {
      final result = await releaseBalanceUseCase!(ReleaseEscrowParams(
        userId: _currentUserId!,
        orderId: event.transactionId,
      ));

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
      // Fallback to mock behavior
      await Future.delayed(const Duration(seconds: 1));
      final updatedData = currentData.copyWith(
        availableBalance: currentData.availableBalance,
        pendingBalance: currentData.pendingBalance - event.amount,
      );
      emit(LoadedState<WalletData>(
        data: updatedData,
        lastUpdated: DateTime.now(),
      ));
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
