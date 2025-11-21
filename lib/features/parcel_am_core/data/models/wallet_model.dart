import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletModel {
  final String id;
  final String userId;
  final double availableBalance;
  final double heldBalance;
  final double totalBalance;
  final String currency;
  final DateTime lastUpdated;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.heldBalance,
    required this.totalBalance,
    required this.currency,
    required this.lastUpdated,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      availableBalance: (json['availableBalance'] as num).toDouble(),
      heldBalance: (json['heldBalance'] as num).toDouble(),
      totalBalance: (json['totalBalance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      lastUpdated: json['lastUpdated'] is Timestamp
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.parse(json['lastUpdated'] as String),
    );
  }

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      userId: data['userId'] as String,
      availableBalance: (data['availableBalance'] as num).toDouble(),
      heldBalance: (data['heldBalance'] as num).toDouble(),
      totalBalance: (data['totalBalance'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      lastUpdated: data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      userId: entity.userId,
      availableBalance: entity.availableBalance,
      heldBalance: entity.heldBalance,
      totalBalance: entity.totalBalance,
      currency: entity.currency,
      lastUpdated: entity.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'availableBalance': availableBalance,
      'heldBalance': heldBalance,
      'totalBalance': totalBalance,
      'currency': currency,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  WalletEntity toEntity() {
    return WalletEntity(
      id: id,
      userId: userId,
      availableBalance: availableBalance,
      heldBalance: heldBalance,
      totalBalance: totalBalance,
      currency: currency,
      lastUpdated: lastUpdated,
    );
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    double? availableBalance,
    double? heldBalance,
    double? totalBalance,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      availableBalance: availableBalance ?? this.availableBalance,
      heldBalance: heldBalance ?? this.heldBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
