import 'package:equatable/equatable.dart';

/// Enum representing withdrawal order status
enum WithdrawalStatus {
  pending,
  processing,
  success,
  failed,
  reversed,
}

/// Entity representing a withdrawal order
class WithdrawalOrderEntity extends Equatable {
  final String id; // Withdrawal reference: WTH-{timestamp}-{uuid}
  final String userId;
  final double amount;
  final BankAccountInfo bankAccount;
  final WithdrawalStatus status;
  final String recipientCode;
  final String? transferCode; // From Paystack transfer response
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
  final Map<String, dynamic> metadata;
  final String? failureReason;
  final String? reversalReason;

  const WithdrawalOrderEntity({
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

  WithdrawalOrderEntity copyWith({
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
    return WithdrawalOrderEntity(
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

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        bankAccount,
        status,
        recipientCode,
        transferCode,
        createdAt,
        updatedAt,
        processedAt,
        metadata,
        failureReason,
        reversalReason,
      ];
}

/// Embedded bank account information in withdrawal order
class BankAccountInfo extends Equatable {
  final String id;
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String bankName;

  const BankAccountInfo({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.bankName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'bankCode': bankCode,
      'bankName': bankName,
    };
  }

  factory BankAccountInfo.fromJson(Map<String, dynamic> json) {
    return BankAccountInfo(
      id: json['id'] as String? ?? '',
      accountNumber: json['accountNumber'] as String,
      accountName: json['accountName'] as String,
      bankCode: json['bankCode'] as String,
      bankName: json['bankName'] as String,
    );
  }

  @override
  List<Object?> get props => [id, accountNumber, accountName, bankCode, bankName];
}
