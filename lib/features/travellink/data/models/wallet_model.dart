import '../../domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.uid,
    required super.availableBalance,
    required super.pendingBalance,
    required super.transactions,
    required super.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      uid: json['uid'],
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? 0).toDouble(),
      transactions: json['transactions'] ?? [],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'transactions': transactions,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      uid: entity.uid,
      availableBalance: entity.availableBalance,
      pendingBalance: entity.pendingBalance,
      transactions: entity.transactions,
      updatedAt: entity.updatedAt,
    );
  }

  WalletEntity toEntity() {
    return WalletEntity(
      uid: uid,
      availableBalance: availableBalance,
      pendingBalance: pendingBalance,
      transactions: transactions,
      updatedAt: updatedAt,
    );
  }

  @override
  WalletModel copyWith({
    String? uid,
    double? availableBalance,
    double? pendingBalance,
    List<dynamic>? transactions,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      uid: uid ?? this.uid,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      transactions: transactions ?? this.transactions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
