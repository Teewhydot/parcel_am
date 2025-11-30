import '../../../domain/entities/user_bank_account_entity.dart';
import '../../../domain/entities/withdrawal_order_entity.dart';

class WithdrawalData {
  final double? amount;
  final UserBankAccountEntity? selectedBankAccount;
  final WithdrawalOrderEntity? withdrawalOrder;
  final bool isInitiating;
  final String? amountError;

  const WithdrawalData({
    this.amount,
    this.selectedBankAccount,
    this.withdrawalOrder,
    this.isInitiating = false,
    this.amountError,
  });

  bool get hasValidAmount => amount != null && amount! > 0 && amountError == null;
  bool get hasBankAccount => selectedBankAccount != null;
  bool get canInitiateWithdrawal => hasValidAmount && hasBankAccount && !isInitiating;

  WithdrawalData copyWith({
    double? amount,
    UserBankAccountEntity? selectedBankAccount,
    WithdrawalOrderEntity? withdrawalOrder,
    bool? isInitiating,
    String? amountError,
    bool clearAmount = false,
    bool clearBankAccount = false,
    bool clearWithdrawalOrder = false,
    bool clearAmountError = false,
  }) {
    return WithdrawalData(
      amount: clearAmount ? null : (amount ?? this.amount),
      selectedBankAccount: clearBankAccount ? null : (selectedBankAccount ?? this.selectedBankAccount),
      withdrawalOrder: clearWithdrawalOrder ? null : (withdrawalOrder ?? this.withdrawalOrder),
      isInitiating: isInitiating ?? this.isInitiating,
      amountError: clearAmountError ? null : (amountError ?? this.amountError),
    );
  }
}
