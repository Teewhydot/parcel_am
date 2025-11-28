import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class WalletStarted extends WalletEvent {
  final String userId;

  const WalletStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

class WalletsFundRequested extends WalletEvent {
  final String userId,email,transactionId;
  final double amount;


  const WalletsFundRequested( {
    required this.userId,
    required this.email,
    required this.transactionId,
    required this.amount,
  });

}

class WalletRefreshRequested extends WalletEvent {
  final String userId;

  const WalletRefreshRequested(this.userId);

  @override
  List<Object?> get props => [userId];
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

class WalletConnectivityChanged extends WalletEvent {
  final bool isOnline;

  const WalletConnectivityChanged({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}
