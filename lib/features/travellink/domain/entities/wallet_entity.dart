import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String uid;
  final double availableBalance;
  final double pendingBalance;
  final List<dynamic> transactions;
  final DateTime updatedAt;

  const WalletEntity({
    required this.uid,
    required this.availableBalance,
    required this.pendingBalance,
    required this.transactions,
    required this.updatedAt,
  });

  WalletEntity copyWith({
    String? uid,
    double? availableBalance,
    double? pendingBalance,
    List<dynamic>? transactions,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      uid: uid ?? this.uid,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      transactions: transactions ?? this.transactions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        availableBalance,
        pendingBalance,
        transactions,
        updatedAt,
      ];
}
