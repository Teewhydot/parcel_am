import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_bank_account_entity.dart';

class UserBankAccountModel {
  final String id;
  final String userId;
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String bankName;
  final String recipientCode;
  final bool verified;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserBankAccountModel({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.bankName,
    required this.recipientCode,
    this.verified = true,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBankAccountModel.fromJson(Map<String, dynamic> json) {
    return UserBankAccountModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      accountNumber: json['accountNumber'] as String,
      accountName: json['accountName'] as String,
      bankCode: json['bankCode'] as String,
      bankName: json['bankName'] as String,
      recipientCode: json['recipientCode'] as String,
      verified: json['verified'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory UserBankAccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBankAccountModel(
      id: doc.id,
      userId: data['userId'] as String,
      accountNumber: data['accountNumber'] as String,
      accountName: data['accountName'] as String,
      bankCode: data['bankCode'] as String,
      bankName: data['bankName'] as String,
      recipientCode: data['recipientCode'] as String,
      verified: data['verified'] as bool? ?? true,
      active: data['active'] as bool? ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory UserBankAccountModel.fromEntity(UserBankAccountEntity entity) {
    return UserBankAccountModel(
      id: entity.id,
      userId: entity.userId,
      accountNumber: entity.accountNumber,
      accountName: entity.accountName,
      bankCode: entity.bankCode,
      bankName: entity.bankName,
      recipientCode: entity.recipientCode,
      verified: entity.verified,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'bankCode': bankCode,
      'bankName': bankName,
      'recipientCode': recipientCode,
      'verified': verified,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserBankAccountEntity toEntity() {
    return UserBankAccountEntity(
      id: id,
      userId: userId,
      accountNumber: accountNumber,
      accountName: accountName,
      bankCode: bankCode,
      bankName: bankName,
      recipientCode: recipientCode,
      verified: verified,
      active: active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  UserBankAccountModel copyWith({
    String? id,
    String? userId,
    String? accountNumber,
    String? accountName,
    String? bankCode,
    String? bankName,
    String? recipientCode,
    bool? verified,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserBankAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      recipientCode: recipientCode ?? this.recipientCode,
      verified: verified ?? this.verified,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
