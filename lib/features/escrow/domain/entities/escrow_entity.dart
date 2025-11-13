import 'package:equatable/equatable.dart';
import 'escrow_status.dart';

class EscrowEntity extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final String currency;
  final EscrowStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime? heldAt;
  final DateTime? releasedAt;
  final DateTime? cancelledAt;
  final DateTime? disputedAt;
  final String? disputeReason;
  final Map<String, dynamic>? metadata;

  const EscrowEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
    required this.createdAt,
    this.heldAt,
    this.releasedAt,
    this.cancelledAt,
    this.disputedAt,
    this.disputeReason,
    this.metadata,
  });

  EscrowEntity copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    double? amount,
    String? currency,
    EscrowStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? heldAt,
    DateTime? releasedAt,
    DateTime? cancelledAt,
    DateTime? disputedAt,
    String? disputeReason,
    Map<String, dynamic>? metadata,
  }) {
    return EscrowEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      heldAt: heldAt ?? this.heldAt,
      releasedAt: releasedAt ?? this.releasedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      disputedAt: disputedAt ?? this.disputedAt,
      disputeReason: disputeReason ?? this.disputeReason,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        amount,
        currency,
        status,
        description,
        createdAt,
        heldAt,
        releasedAt,
        cancelledAt,
        disputedAt,
        disputeReason,
        metadata,
      ];
}
