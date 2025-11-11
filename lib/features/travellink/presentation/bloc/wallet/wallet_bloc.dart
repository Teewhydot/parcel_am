import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';
import 'wallet_data.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  Timer? _refreshTimer;

  WalletBloc() : super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletRefreshRequested>(_onRefreshRequested);
    on<WalletBalanceUpdated>(_onBalanceUpdated);
    on<WalletEscrowHoldRequested>(_onEscrowHoldRequested);
    on<WalletEscrowReleaseRequested>(_onEscrowReleaseRequested);
    on<WalletBalanceRefreshRequested>(_onBalanceRefreshRequested);

    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => add(const WalletRefreshRequested()),
    );
  }

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    await _fetchWalletData(emit);
  }

  Future<void> _onRefreshRequested(
    WalletRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    await _fetchWalletData(emit);
  }

  Future<void> _onBalanceUpdated(
    WalletBalanceUpdated event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoaded(
      availableBalance: event.availableBalance,
      pendingBalance: event.pendingBalance,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onEscrowHoldRequested(
    WalletEscrowHoldRequested event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WalletLoaded) {
      emit(const WalletError(message: 'Wallet not loaded'));
      return;
    }

    if (currentState.availableBalance < event.amount) {
      emit(const WalletError(message: 'Insufficient balance'));
      return;
    }

    emit(const WalletLoading());

    await Future.delayed(const Duration(seconds: 2));

    emit(WalletLoaded(
      availableBalance: currentState.availableBalance - event.amount,
      pendingBalance: currentState.pendingBalance + event.amount,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onEscrowReleaseRequested(
    WalletEscrowReleaseRequested event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WalletLoaded) {
      emit(const WalletError(message: 'Wallet not loaded'));
      return;
    }

    emit(const WalletLoading());

    await Future.delayed(const Duration(seconds: 1));

    emit(WalletLoaded(
      availableBalance: currentState.availableBalance,
      pendingBalance: currentState.pendingBalance - event.amount,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onBalanceRefreshRequested(
    WalletBalanceRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is WalletLoaded) {
      emit(const WalletLoading());
      await Future.delayed(const Duration(milliseconds: 500));
      emit(WalletLoaded(
        availableBalance: currentState.availableBalance,
        pendingBalance: currentState.pendingBalance,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> _fetchWalletData(Emitter<WalletState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      emit(const WalletLoaded(
        availableBalance: 50000.0,
        pendingBalance: 0.0,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
