import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/escrow_entity.dart';
import '../../../escrow/domain/entities/escrow_status.dart';

class EscrowModel {
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

  const EscrowModel({
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

  factory EscrowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EscrowModel(
      id: doc.id,
      parcelId: data['parcelId'] as String,
      senderId: data['senderId'] as String,
      travelerId: data['travelerId'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      heldAt: data['heldAt'] is Timestamp
          ? (data['heldAt'] as Timestamp).toDate()
          : null,
      releasedAt: data['releasedAt'] is Timestamp
          ? (data['releasedAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] is Timestamp
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      releaseCondition: data['releaseCondition'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  factory EscrowModel.fromEntity(EscrowEntity entity) {
    return EscrowModel(
      id: entity.id,
      parcelId: entity.parcelId,
      senderId: entity.senderId,
      travelerId: entity.travelerId,
      amount: entity.amount,
      currency: entity.currency,
      status: entity.status,
      createdAt: entity.createdAt,
      heldAt: entity.heldAt,
      releasedAt: entity.releasedAt,
      expiresAt: entity.expiresAt,
      releaseCondition: entity.releaseCondition,
      metadata: entity.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parcelId': parcelId,
      'senderId': senderId,
      'travelerId': travelerId,
      'amount': amount,
      'currency': currency,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'heldAt': heldAt != null ? Timestamp.fromDate(heldAt!) : null,
      'releasedAt':
          releasedAt != null ? Timestamp.fromDate(releasedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'releaseCondition': releaseCondition,
      'metadata': metadata,
    };
  }

  EscrowEntity toEntity() {
    return EscrowEntity(
      id: id,
      parcelId: parcelId,
      senderId: senderId,
      travelerId: travelerId,
      amount: amount,
      currency: currency,
      status: status,
      createdAt: createdAt,
      heldAt: heldAt,
      releasedAt: releasedAt,
      expiresAt: expiresAt,
      releaseCondition: releaseCondition,
      metadata: metadata,
    );
  }

  EscrowModel copyWith({
    String? id,
    String? parcelId,
    String? senderId,
    String? travelerId,
    double? amount,
    String? currency,
    EscrowStatus? status,
    DateTime? createdAt,
    DateTime? heldAt,
    DateTime? releasedAt,
    DateTime? expiresAt,
    String? releaseCondition,
    Map<String, dynamic>? metadata,
  }) {
    return EscrowModel(
      id: id ?? this.id,
      parcelId: parcelId ?? this.parcelId,
      senderId: senderId ?? this.senderId,
      travelerId: travelerId ?? this.travelerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      heldAt: heldAt ?? this.heldAt,
      releasedAt: releasedAt ?? this.releasedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      releaseCondition: releaseCondition ?? this.releaseCondition,
      metadata: metadata ?? this.metadata,
    );
  }

  static EscrowStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return EscrowStatus.pending;
      case 'held':
        return EscrowStatus.held;
      case 'released':
        return EscrowStatus.released;
      case 'cancelled':
        return EscrowStatus.cancelled;
      case 'refunded':
        return EscrowStatus.refunded;
      case 'disputed':
        return EscrowStatus.disputed;
      default:
        return EscrowStatus.pending;
    }
  }

  static String _statusToString(EscrowStatus status) {
    return status.name;
  }
}
