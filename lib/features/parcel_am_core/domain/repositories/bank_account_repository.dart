import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bank_info_entity.dart';
import '../entities/user_bank_account_entity.dart';

abstract class BankAccountRepository {
  /// Get list of Nigerian banks
  Future<Either<Failure, List<BankInfoEntity>>> getBankList();

  /// Verify bank account details and return account name
  Future<Either<Failure, Map<String, dynamic>>> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  });

  /// Add and save verified bank account
  Future<Either<Failure, UserBankAccountEntity>> addBankAccount({
    required String userId,
    required String accountNumber,
    required String accountName,
    required String bankCode,
    required String bankName,
  });

  /// Get user's saved bank accounts
  Future<Either<Failure, List<UserBankAccountEntity>>> getUserBankAccounts(String userId);

  /// Delete user bank account (soft delete)
  Future<Either<Failure, void>> deleteBankAccount({
    required String userId,
    required String accountId,
  });
}
