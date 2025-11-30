import '../../../domain/entities/bank_info_entity.dart';
import '../../../domain/entities/user_bank_account_entity.dart';

class BankAccountData {
  final List<BankInfoEntity> bankList;
  final List<UserBankAccountEntity> userBankAccounts;
  final VerificationResult? verificationResult;
  final bool isVerifying;
  final bool isSaving;

  const BankAccountData({
    this.bankList = const [],
    this.userBankAccounts = const [],
    this.verificationResult,
    this.isVerifying = false,
    this.isSaving = false,
  });

  bool get hasReachedMaxAccounts => userBankAccounts.length >= 5;
  bool get hasBankAccounts => userBankAccounts.isNotEmpty;
  int get remainingAccountSlots => 5 - userBankAccounts.length;

  BankAccountData copyWith({
    List<BankInfoEntity>? bankList,
    List<UserBankAccountEntity>? userBankAccounts,
    VerificationResult? verificationResult,
    bool? isVerifying,
    bool? isSaving,
    bool clearVerification = false,
  }) {
    return BankAccountData(
      bankList: bankList ?? this.bankList,
      userBankAccounts: userBankAccounts ?? this.userBankAccounts,
      verificationResult: clearVerification ? null : (verificationResult ?? this.verificationResult),
      isVerifying: isVerifying ?? this.isVerifying,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class VerificationResult {
  final String accountName;
  final String accountNumber;
  final String bankCode;

  const VerificationResult({
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
  });
}
