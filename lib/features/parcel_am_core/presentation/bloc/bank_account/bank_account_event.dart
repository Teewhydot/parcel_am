import 'package:equatable/equatable.dart';

abstract class BankAccountEvent extends Equatable {
  const BankAccountEvent();

  @override
  List<Object?> get props => [];
}

class BankAccountLoadRequested extends BankAccountEvent {
  final String userId;

  const BankAccountLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class BankListLoadRequested extends BankAccountEvent {
  const BankListLoadRequested();
}

class BankAccountVerificationRequested extends BankAccountEvent {
  final String accountNumber;
  final String bankCode;

  const BankAccountVerificationRequested({
    required this.accountNumber,
    required this.bankCode,
  });

  @override
  List<Object?> get props => [accountNumber, bankCode];
}

class BankAccountAddRequested extends BankAccountEvent {
  final String userId;
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String bankName;

  const BankAccountAddRequested({
    required this.userId,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.bankName,
  });

  @override
  List<Object?> get props => [userId, accountNumber, accountName, bankCode, bankName];
}

class BankAccountDeleteRequested extends BankAccountEvent {
  final String userId;
  final String accountId;

  const BankAccountDeleteRequested({
    required this.userId,
    required this.accountId,
  });

  @override
  List<Object?> get props => [userId, accountId];
}

class BankAccountRefreshRequested extends BankAccountEvent {
  final String userId;

  const BankAccountRefreshRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class BankAccountVerificationCleared extends BankAccountEvent {
  const BankAccountVerificationCleared();
}
