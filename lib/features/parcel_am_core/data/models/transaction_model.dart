import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionModel {
  final String id;
  final String walletId;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String currency;
  final DateTime timestamp;
  final String? description;
  final String? referenceId;
  final Map<String, dynamic> metadata;

  const TransactionModel({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.currency,
    required this.timestamp,
    this.description,
    this.referenceId,
    this.metadata = const {},
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.payment,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      currency: json['currency'] as String? ?? 'USD',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
      referenceId: json['referenceId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      walletId: data['walletId'] as String,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.payment,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      currency: data['currency'] as String? ?? 'USD',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      description: data['description'] as String?,
      referenceId: data['referenceId'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      walletId: entity.walletId,
      userId: entity.userId,
      amount: entity.amount,
      type: entity.type,
      status: entity.status,
      currency: entity.currency,
      timestamp: entity.timestamp,
      description: entity.description,
      referenceId: entity.referenceId,
      metadata: entity.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'currency': currency,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'referenceId': referenceId,
      'metadata': metadata,
    };
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      walletId: walletId,
      userId: userId,
      amount: amount,
      type: type,
      status: status,
      currency: currency,
      timestamp: timestamp,
      description: description,
      referenceId: referenceId,
      metadata: metadata,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? walletId,
    String? userId,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    String? currency,
    DateTime? timestamp,
    String? description,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
    );
  }
}
