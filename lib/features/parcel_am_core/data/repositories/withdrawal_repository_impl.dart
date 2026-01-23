import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/withdrawal_order_entity.dart';
import '../../domain/repositories/withdrawal_repository.dart';
import '../datasources/withdrawal_remote_data_source.dart';

class WithdrawalRepositoryImpl implements WithdrawalRepository {
  final WithdrawalRemoteDataSource _remoteDataSource;

  // Withdrawal limits in NGN
  static const double minWithdrawalAmount = 100.0;
  static const double maxWithdrawalAmount = 500000.0;

  WithdrawalRepositoryImpl({WithdrawalRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<WithdrawalRemoteDataSource>();

  @override
  String generateWithdrawalReference() {
    return _remoteDataSource.generateWithdrawalReference();
  }

  @override
  bool validateWithdrawalAmount(double amount, double availableBalance) {
    if (amount < minWithdrawalAmount) {
      Logger.logError('Withdrawal amount below minimum: $amount');
      return false;
    }

    if (amount > maxWithdrawalAmount) {
      Logger.logError('Withdrawal amount above maximum: $amount');
      return false;
    }

    if (amount > availableBalance) {
      Logger.logError('Insufficient balance: $amount > $availableBalance');
      return false;
    }

    return true;
  }

  @override
  Future<Either<Failure, WithdrawalOrderEntity>> initiateWithdrawal({
    required String userId,
    required double amount,
    required String recipientCode,
    required String withdrawalReference,
    required BankAccountInfo bankAccount,
  }) {
    return ErrorHandler.handle(
      () async {
        // Validate amount format
        if (amount <= 0) {
          throw const ValidationFailure(failureMessage: 'Amount must be greater than zero');
        }

        if (amount < minWithdrawalAmount) {
          throw ValidationFailure(failureMessage: 'Minimum withdrawal amount is NGN ${minWithdrawalAmount.toStringAsFixed(0)}');
        }

        if (amount > maxWithdrawalAmount) {
          throw ValidationFailure(failureMessage: 'Maximum withdrawal amount is NGN ${maxWithdrawalAmount.toStringAsFixed(0)}');
        }

        final withdrawalModel = await _remoteDataSource.initiateWithdrawal(
          userId: userId,
          amount: amount,
          recipientCode: recipientCode,
          withdrawalReference: withdrawalReference,
          bankAccountId: bankAccount.id,
        );

        return withdrawalModel.toEntity();
      },
      operationName: 'initiateWithdrawal',
    );
  }

  @override
  Future<Either<Failure, WithdrawalOrderEntity>> getWithdrawalOrder(String withdrawalId) {
    return ErrorHandler.handle(
      () async {
        final withdrawalModel = await _remoteDataSource.getWithdrawalOrder(withdrawalId);
        return withdrawalModel.toEntity();
      },
      operationName: 'getWithdrawalOrder',
    );
  }

  @override
  Stream<Either<Failure, WithdrawalOrderEntity>> watchWithdrawalOrder(String withdrawalId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource
          .watchWithdrawalOrder(withdrawalId)
          .map((model) => model.toEntity()),
      operationName: 'watchWithdrawalOrder',
    );
  }

  @override
  Future<Either<Failure, List<WithdrawalOrderEntity>>> getWithdrawalHistory({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    return ErrorHandler.handle(
      () async {
        final withdrawalModels = await _remoteDataSource.getWithdrawalHistory(
          userId: userId,
          limit: limit,
          startAfter: startAfter,
        );

        return withdrawalModels.map((model) => model.toEntity()).toList();
      },
      operationName: 'getWithdrawalHistory',
    );
  }
}
