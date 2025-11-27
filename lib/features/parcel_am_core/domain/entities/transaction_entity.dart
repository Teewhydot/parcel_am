import 'package:equatable/equatable.dart';

enum TransactionType {
  deposit,
  withdrawal,
  hold,
  release,
  payment,
  refund,
  earning
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled
}

class TransactionEntity extends Equatable {
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
  final String idempotencyKey;

  const TransactionEntity({
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
    required this.idempotencyKey,
  });

  TransactionEntity copyWith({
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
    String? idempotencyKey,
  }) {
    return TransactionEntity(
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
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        userId,
        amount,
        type,
        status,
        currency,
        timestamp,
        description,
        referenceId,
        metadata,
        idempotencyKey,
      ];
}
