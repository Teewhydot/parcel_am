import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String id;
  final String userId;
  final double availableBalance;
  final double heldBalance;
  final double totalBalance;
  final String currency;
  final DateTime lastUpdated;

  const WalletEntity({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.heldBalance,
    required this.totalBalance,
    required this.currency,
    required this.lastUpdated,
  });

  WalletEntity copyWith({
    String? id,
    String? userId,
    double? availableBalance,
    double? heldBalance,
    double? totalBalance,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      availableBalance: availableBalance ?? this.availableBalance,
      heldBalance: heldBalance ?? this.heldBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        availableBalance,
        heldBalance,
        totalBalance,
        currency,
        lastUpdated,
      ];
}
