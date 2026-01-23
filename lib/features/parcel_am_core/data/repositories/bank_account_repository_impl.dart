import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/bank_info_entity.dart';
import '../../domain/entities/user_bank_account_entity.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../datasources/bank_account_remote_data_source.dart';

class BankAccountRepositoryImpl implements BankAccountRepository {
  final BankAccountRemoteDataSource _remoteDataSource;

  BankAccountRepositoryImpl({BankAccountRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<BankAccountRemoteDataSource>();

  @override
  Future<Either<Failure, List<BankInfoEntity>>> getBankList() {
    return ErrorHandler.handle(
      () async {
        final bankModels = await _remoteDataSource.getBankList();
        return bankModels.map((model) => model.toEntity()).toList();
      },
      operationName: 'getBankList',
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  }) {
    return ErrorHandler.handle(
      () async {
        // Validate account number format
        if (accountNumber.length != 10 || !RegExp(r'^\d{10}$').hasMatch(accountNumber)) {
          throw const ValidationFailure(failureMessage: 'Account number must be exactly 10 digits');
        }

        // Validate bank code is not empty
        if (bankCode.isEmpty) {
          throw const ValidationFailure(failureMessage: 'Please select a bank');
        }

        return await _remoteDataSource.resolveBankAccount(
          accountNumber: accountNumber,
          bankCode: bankCode,
        );
      },
      operationName: 'verifyBankAccount',
    );
  }

  @override
  Future<Either<Failure, UserBankAccountEntity>> addBankAccount({
    required String userId,
    required String accountNumber,
    required String accountName,
    required String bankCode,
    required String bankName,
  }) {
    return ErrorHandler.handle(
      () async {
        // Validate inputs
        if (accountNumber.length != 10 || !RegExp(r'^\d{10}$').hasMatch(accountNumber)) {
          throw const ValidationFailure(failureMessage: 'Account number must be exactly 10 digits');
        }

        if (accountName.isEmpty) {
          throw const ValidationFailure(failureMessage: 'Account name is required');
        }

        if (bankCode.isEmpty || bankName.isEmpty) {
          throw const ValidationFailure(failureMessage: 'Bank information is required');
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

        return accountModel.toEntity();
      },
      operationName: 'addBankAccount',
    );
  }

  @override
  Future<Either<Failure, List<UserBankAccountEntity>>> getUserBankAccounts(String userId) {
    return ErrorHandler.handle(
      () async {
        final accountModels = await _remoteDataSource.getUserBankAccounts(userId);
        return accountModels.map((model) => model.toEntity()).toList();
      },
      operationName: 'getUserBankAccounts',
    );
  }

  @override
  Future<Either<Failure, void>> deleteBankAccount({
    required String userId,
    required String accountId,
  }) {
    return ErrorHandler.handle(
      () async {
        await _remoteDataSource.deleteUserBankAccount(
          userId: userId,
          accountId: accountId,
        );
      },
      operationName: 'deleteBankAccount',
    );
  }
}
