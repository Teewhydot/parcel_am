import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_bank_account_entity.dart';

abstract class WithdrawalEvent extends Equatable {
  const WithdrawalEvent();

  @override
  List<Object?> get props => [];
}

class WithdrawalAmountChanged extends WithdrawalEvent {
  final String amount;

  const WithdrawalAmountChanged({required this.amount});

  @override
  List<Object?> get props => [amount];
}

class WithdrawalBankAccountSelected extends WithdrawalEvent {
  final UserBankAccountEntity bankAccount;

  const WithdrawalBankAccountSelected({required this.bankAccount});

  @override
  List<Object?> get props => [bankAccount];
}

class WithdrawalInitiateRequested extends WithdrawalEvent {
  final String userId;
  final double amount;
  final UserBankAccountEntity bankAccount;
  final double availableBalance;

  const WithdrawalInitiateRequested({
    required this.userId,
    required this.amount,
    required this.bankAccount,
    required this.availableBalance,
  });

  @override
  List<Object?> get props => [userId, amount, bankAccount, availableBalance];
}

class WithdrawalStatusWatchRequested extends WithdrawalEvent {
  final String withdrawalId;

  const WithdrawalStatusWatchRequested({required this.withdrawalId});

  @override
  List<Object?> get props => [withdrawalId];
}

class WithdrawalRetryRequested extends WithdrawalEvent {
  final String userId;
  final double amount;
  final UserBankAccountEntity bankAccount;

  const WithdrawalRetryRequested({
    required this.userId,
    required this.amount,
    required this.bankAccount,
  });

  @override
  List<Object?> get props => [userId, amount, bankAccount];
}

class WithdrawalReset extends WithdrawalEvent {
  const WithdrawalReset();
}
