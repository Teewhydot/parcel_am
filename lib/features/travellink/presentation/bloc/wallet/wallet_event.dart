import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

class WalletRefreshRequested extends WalletEvent {
  const WalletRefreshRequested();
}

class WalletBalanceUpdated extends WalletEvent {
  final double availableBalance;
  final double pendingBalance;

  const WalletBalanceUpdated({
    required this.availableBalance,
    required this.pendingBalance,
  });

  @override
  List<Object?> get props => [availableBalance, pendingBalance];
}
