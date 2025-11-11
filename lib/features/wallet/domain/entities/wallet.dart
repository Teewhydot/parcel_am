import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String userId;
  final double availableBalance;
  final double pendingBalance;
  final DateTime? lastUpdated;

  const Wallet({
    required this.userId,
    required this.availableBalance,
    required this.pendingBalance,
    this.lastUpdated,
  });

  double get totalBalance => availableBalance + pendingBalance;

  @override
  List<Object?> get props => [userId, availableBalance, pendingBalance, lastUpdated];
}
