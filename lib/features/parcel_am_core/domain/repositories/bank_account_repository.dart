import '../entities/bank_info_entity.dart';
import '../entities/user_bank_account_entity.dart';

abstract class BankAccountRepository {
  /// Get list of Nigerian banks
  Future<List<BankInfoEntity>> getBankList();

  /// Verify bank account details and return account name
  Future<Map<String, dynamic>> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  });

  /// Add and save verified bank account
  Future<UserBankAccountEntity> addBankAccount({
    required String userId,
    required String accountNumber,
    required String accountName,
    required String bankCode,
    required String bankName,
  });

  /// Get user's saved bank accounts
  Future<List<UserBankAccountEntity>> getUserBankAccounts(String userId);

  /// Delete user bank account (soft delete)
  Future<void> deleteBankAccount({
    required String userId,
    required String accountId,
  });
}
