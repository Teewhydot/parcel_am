import 'package:equatable/equatable.dart';

enum EscrowStatus {
  pending,
  held,
  released,
  cancelled,
  refunded,
  disputed,
}

class EscrowEntity extends Equatable {
  final String id;
  final String parcelId;
  final String senderId;
  final String travelerId;
  final double amount;
  final String currency;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime? heldAt;
  final DateTime? releasedAt;
  final DateTime? expiresAt;
  final String? releaseCondition;
  final Map<String, dynamic> metadata;

  const EscrowEntity({
    required this.id,
    required this.parcelId,
    required this.senderId,
    required this.travelerId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.heldAt,
    this.releasedAt,
    this.expiresAt,
    this.releaseCondition,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        id,
        parcelId,
        senderId,
        travelerId,
        amount,
        currency,
        status,
        createdAt,
        heldAt,
        releasedAt,
        expiresAt,
        releaseCondition,
        metadata,
      ];
}
