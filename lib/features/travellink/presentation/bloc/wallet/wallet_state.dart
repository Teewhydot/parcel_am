import 'package:equatable/equatable.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final double availableBalance;
  final double pendingBalance;
  final DateTime lastUpdated;

  const WalletLoaded({
    required this.availableBalance,
    required this.pendingBalance,
    required this.lastUpdated,
  });

  double get totalBalance => availableBalance + pendingBalance;

  @override
  List<Object?> get props => [availableBalance, pendingBalance, lastUpdated];
}

class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}
