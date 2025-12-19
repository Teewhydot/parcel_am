import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/withdrawal_order_entity.dart';

abstract class WithdrawalRepository {
  /// Generate unique withdrawal reference
  String generateWithdrawalReference();

  /// Validate withdrawal amount
  bool validateWithdrawalAmount(double amount, double availableBalance);

  /// Initiate withdrawal
  Future<WithdrawalOrderEntity> initiateWithdrawal({
    required String userId,
    required double amount,
    required String recipientCode,
    required String withdrawalReference,
    required BankAccountInfo bankAccount,
  });

  /// Get withdrawal order by ID
  Future<WithdrawalOrderEntity> getWithdrawalOrder(String withdrawalId);

  /// Watch withdrawal order for real-time updates
  Stream<WithdrawalOrderEntity> watchWithdrawalOrder(String withdrawalId);

  /// Get user's withdrawal history
  Future<List<WithdrawalOrderEntity>> getWithdrawalHistory({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  });
}
