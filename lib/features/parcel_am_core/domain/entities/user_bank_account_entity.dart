import 'package:equatable/equatable.dart';

/// Entity representing a user's saved bank account
class UserBankAccountEntity extends Equatable {
  final String id;
  final String userId;
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String bankName;
  final String recipientCode; // Paystack transfer recipient code
  final bool verified;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserBankAccountEntity({
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

  /// Returns masked account number (shows last 4 digits)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    final maskedPart = '*' * (accountNumber.length - 4);
    return '$maskedPart$lastFour';
  }

  /// Validates account number is 10 digits
  bool get isValidAccountNumber {
    return accountNumber.length == 10 &&
           RegExp(r'^\d{10}$').hasMatch(accountNumber);
  }

  /// Validates bank code is not empty
  bool get isValidBankCode {
    return bankCode.isNotEmpty;
  }

  UserBankAccountEntity copyWith({
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
    return UserBankAccountEntity(
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

  @override
  List<Object?> get props => [
        id,
        userId,
        accountNumber,
        accountName,
        bankCode,
        bankName,
        recipientCode,
        verified,
        active,
        createdAt,
        updatedAt,
      ];
}
