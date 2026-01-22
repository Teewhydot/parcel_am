import 'package:get_it/get_it.dart';
import '../../domain/entities/bank_info_entity.dart';
import '../../domain/entities/user_bank_account_entity.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../datasources/bank_account_remote_data_source.dart';
import '../../../../core/utils/logger.dart';

class BankAccountRepositoryImpl implements BankAccountRepository {
  final BankAccountRemoteDataSource _remoteDataSource;

  BankAccountRepositoryImpl({BankAccountRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<BankAccountRemoteDataSource>();

  @override
  Future<List<BankInfoEntity>> getBankList() async {
    try {
      final bankModels = await _remoteDataSource.getBankList();
      return bankModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      Logger.logError('Repository: Error fetching bank list: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      // Validate account number format
      if (accountNumber.length != 10 || !RegExp(r'^\d{10}$').hasMatch(accountNumber)) {
        throw Exception('Account number must be exactly 10 digits');
      }

      // Validate bank code is not empty
      if (bankCode.isEmpty) {
        throw Exception('Please select a bank');
      }

      final result = await _remoteDataSource.resolveBankAccount(
        accountNumber: accountNumber,
        bankCode: bankCode,
      );

      return result;
    } catch (e) {
      Logger.logError('Repository: Error verifying bank account: $e');
      rethrow;
    }
  }

  @override
  Future<UserBankAccountEntity> addBankAccount({
    required String userId,
    required String accountNumber,
    required String accountName,
    required String bankCode,
    required String bankName,
  }) async {
    try {
      // Validate inputs
      if (accountNumber.length != 10 || !RegExp(r'^\d{10}$').hasMatch(accountNumber)) {
        throw Exception('Account number must be exactly 10 digits');
      }

      if (accountName.isEmpty) {
        throw Exception('Account name is required');
      }

      if (bankCode.isEmpty || bankName.isEmpty) {
        throw Exception('Bank information is required');
      }

      // Create transfer recipient on Paystack
      final recipientCode = await _remoteDataSource.createTransferRecipient(
        accountNumber: accountNumber,
        accountName: accountName,
        bankCode: bankCode,
      );

      // Save bank account to Firestore
      final accountModel = await _remoteDataSource.saveUserBankAccount(
        userId: userId,
        accountNumber: accountNumber,
        accountName: accountName,
        bankCode: bankCode,
        bankName: bankName,
        recipientCode: recipientCode,
      );

      Logger.logSuccess('Bank account added successfully: $accountName');
      return accountModel.toEntity();
    } catch (e) {
      Logger.logError('Repository: Error adding bank account: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserBankAccountEntity>> getUserBankAccounts(String userId) async {
    try {
      final accountModels = await _remoteDataSource.getUserBankAccounts(userId);
      return accountModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      Logger.logError('Repository: Error fetching user bank accounts: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBankAccount({
    required String userId,
    required String accountId,
  }) async {
    try {
      await _remoteDataSource.deleteUserBankAccount(
        userId: userId,
        accountId: accountId,
      );
      Logger.logSuccess('Bank account deleted successfully');
    } catch (e) {
      Logger.logError('Repository: Error deleting bank account: $e');
      rethrow;
    }
  }
}
