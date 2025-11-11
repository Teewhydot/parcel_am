import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  Timer? _refreshTimer;

  WalletBloc() : super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletRefreshRequested>(_onRefreshRequested);
    on<WalletBalanceUpdated>(_onBalanceUpdated);

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

  Future<void> _fetchWalletData(Emitter<WalletState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      emit(WalletLoaded(
        availableBalance: 45600.00,
        pendingBalance: 12400.00,
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
