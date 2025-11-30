import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/withdrawal_order_entity.dart';

class WithdrawalOrderModel {
  final String id;
  final String userId;
  final double amount;
  final BankAccountInfo bankAccount;
  final WithdrawalStatus status;
  final String recipientCode;
  final String? transferCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
  final Map<String, dynamic> metadata;
  final String? failureReason;
  final String? reversalReason;

  const WithdrawalOrderModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.bankAccount,
    required this.status,
    required this.recipientCode,
    this.transferCode,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
    this.metadata = const {},
    this.failureReason,
    this.reversalReason,
  });

  factory WithdrawalOrderModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalOrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      bankAccount: BankAccountInfo.fromJson(
        json['bankAccount'] as Map<String, dynamic>,
      ),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      recipientCode: json['recipientCode'] as String,
      transferCode: json['transferCode'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
      processedAt: json['processedAt'] != null
          ? (json['processedAt'] is Timestamp
              ? (json['processedAt'] as Timestamp).toDate()
              : DateTime.parse(json['processedAt'] as String))
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      failureReason: json['failureReason'] as String?,
      reversalReason: json['reversalReason'] as String?,
    );
  }

  factory WithdrawalOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalOrderModel(
      id: doc.id,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      bankAccount: BankAccountInfo.fromJson(
        data['bankAccount'] as Map<String, dynamic>,
      ),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      recipientCode: data['recipientCode'] as String,
      transferCode: data['transferCode'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] is Timestamp
              ? (data['processedAt'] as Timestamp).toDate()
              : null)
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      failureReason: data['failureReason'] as String?,
      reversalReason: data['reversalReason'] as String?,
    );
  }

  factory WithdrawalOrderModel.fromEntity(WithdrawalOrderEntity entity) {
    return WithdrawalOrderModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      bankAccount: entity.bankAccount,
      status: entity.status,
      recipientCode: entity.recipientCode,
      transferCode: entity.transferCode,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      processedAt: entity.processedAt,
      metadata: entity.metadata,
      failureReason: entity.failureReason,
      reversalReason: entity.reversalReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'bankAccount': bankAccount.toJson(),
      'status': status.name,
      'recipientCode': recipientCode,
      'transferCode': transferCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'metadata': metadata,
      'failureReason': failureReason,
      'reversalReason': reversalReason,
    };
  }

  WithdrawalOrderEntity toEntity() {
    return WithdrawalOrderEntity(
      id: id,
      userId: userId,
      amount: amount,
      bankAccount: bankAccount,
      status: status,
      recipientCode: recipientCode,
      transferCode: transferCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
      processedAt: processedAt,
      metadata: metadata,
      failureReason: failureReason,
      reversalReason: reversalReason,
    );
  }

  WithdrawalOrderModel copyWith({
    String? id,
    String? userId,
    double? amount,
    BankAccountInfo? bankAccount,
    WithdrawalStatus? status,
    String? recipientCode,
    String? transferCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? processedAt,
    Map<String, dynamic>? metadata,
    String? failureReason,
    String? reversalReason,
  }) {
    return WithdrawalOrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      bankAccount: bankAccount ?? this.bankAccount,
      status: status ?? this.status,
      recipientCode: recipientCode ?? this.recipientCode,
      transferCode: transferCode ?? this.transferCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedAt: processedAt ?? this.processedAt,
      metadata: metadata ?? this.metadata,
      failureReason: failureReason ?? this.failureReason,
      reversalReason: reversalReason ?? this.reversalReason,
    );
  }
}
