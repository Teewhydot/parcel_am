import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/withdrawal_order_entity.dart';
import '../../domain/repositories/withdrawal_repository.dart';
import '../datasources/withdrawal_remote_data_source.dart';

class WithdrawalRepositoryImpl implements WithdrawalRepository {
  final WithdrawalRemoteDataSource remoteDataSource;

  // Withdrawal limits in NGN
  static const double minWithdrawalAmount = 100.0;
  static const double maxWithdrawalAmount = 500000.0;

  WithdrawalRepositoryImpl({required this.remoteDataSource});

  @override
  String generateWithdrawalReference() {
    return remoteDataSource.generateWithdrawalReference();
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
  Future<WithdrawalOrderEntity> initiateWithdrawal({
    required String userId,
    required double amount,
    required String recipientCode,
    required String withdrawalReference,
    required BankAccountInfo bankAccount,
  }) async {
    try {
      // Validate amount format
      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      if (amount < minWithdrawalAmount) {
        throw Exception('Minimum withdrawal amount is NGN ${minWithdrawalAmount.toStringAsFixed(0)}');
      }

      if (amount > maxWithdrawalAmount) {
        throw Exception('Maximum withdrawal amount is NGN ${maxWithdrawalAmount.toStringAsFixed(0)}');
      }

      final withdrawalModel = await remoteDataSource.initiateWithdrawal(
        userId: userId,
        amount: amount,
        recipientCode: recipientCode,
        withdrawalReference: withdrawalReference,
        bankAccountId: bankAccount.id,
      );

      Logger.logSuccess('Withdrawal initiated successfully: $withdrawalReference');
      return withdrawalModel.toEntity();
    } catch (e) {
      Logger.logError('Repository: Error initiating withdrawal: $e');
      rethrow;
    }
  }

  @override
  Future<WithdrawalOrderEntity> getWithdrawalOrder(String withdrawalId) async {
    try {
      final withdrawalModel = await remoteDataSource.getWithdrawalOrder(withdrawalId);
      return withdrawalModel.toEntity();
    } catch (e) {
      Logger.logError('Repository: Error fetching withdrawal order: $e');
      rethrow;
    }
  }

  @override
  Stream<WithdrawalOrderEntity> watchWithdrawalOrder(String withdrawalId) {
    try {
      return remoteDataSource
          .watchWithdrawalOrder(withdrawalId)
          .map((model) => model.toEntity());
    } catch (e) {
      Logger.logError('Repository: Error watching withdrawal order: $e');
      rethrow;
    }
  }

  @override
  Future<List<WithdrawalOrderEntity>> getWithdrawalHistory({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final withdrawalModels = await remoteDataSource.getWithdrawalHistory(
        userId: userId,
        limit: limit,
        startAfter: startAfter,
      );

      return withdrawalModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      Logger.logError('Repository: Error fetching withdrawal history: $e');
      rethrow;
    }
  }
}
