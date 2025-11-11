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

class WalletEscrowHoldRequested extends WalletEvent {
  final String transactionId;
  final double amount;
  final String packageId;

  const WalletEscrowHoldRequested({
    required this.transactionId,
    required this.amount,
    required this.packageId,
  });

  @override
  List<Object?> get props => [transactionId, amount, packageId];
}

class WalletEscrowReleaseRequested extends WalletEvent {
  final String transactionId;
  final double amount;

  const WalletEscrowReleaseRequested({
    required this.transactionId,
    required this.amount,
  });

  @override
  List<Object?> get props => [transactionId, amount];
}

class WalletBalanceRefreshRequested extends WalletEvent {
  const WalletBalanceRefreshRequested();
}
