import 'package:dartz/dartz.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';
import 'package:parcel_am/features/payments/data/repositories/paystack_payment_repository_impl.dart';

import '../../../../core/errors/failures.dart';
import '../entities/paystack_transaction_entity.dart';
import '../repositories/paystack_payment_repository.dart';

class PaystackPaymentUseCase {
  final  _repository = PaystackPaymentRepositoryImpl();

  /// Initialize wallet funding payment
  /// [transactionId] - Unique transaction ID for the wallet top-up
  /// [amount] - Amount to fund the wallet with
  /// [email] - User's email address
  /// [metadata] - Optional metadata (userId, purpose, etc.)
  Future<Either<Failure, PaystackTransactionEntity>> initializeWalletFunding({
    required String transactionId,
    required double amount,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    if (transactionId.isEmpty) {
      return Left(
        InvalidDataFailure(failureMessage: 'Transaction ID cannot be empty'),
      );
    }

    if (amount <= 0) {
      return Left(
        InvalidDataFailure(failureMessage: 'Amount must be greater than zero'),
      );
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      return Left(
        InvalidDataFailure(failureMessage: 'Valid email is required'),
      );
    }

    return await _repository.initializePayment(
      orderId: transactionId, // Using orderId param for transaction ID
      amount: amount,
      email: email,
      metadata: {
        ...?metadata,
        'purpose': 'wallet_funding',
        'type': 'wallet_topup',
      },
    );
  }

  /// Verify wallet funding payment
  Future<Either<Failure, PaystackTransactionEntity>> verifyWalletFunding({
    required String reference,
    required String transactionId,
  }) async {
    if (reference.isEmpty) {
      return Left(
        InvalidDataFailure(failureMessage: 'Payment reference cannot be empty'),
      );
    }

    if (transactionId.isEmpty) {
      return Left(
        InvalidDataFailure(failureMessage: 'Transaction ID cannot be empty'),
      );
    }

    return await _repository.verifyPayment(
      reference: reference,
      orderId: transactionId, // Using orderId param for transaction ID
    );
  }

  Future<Either<Failure, PaystackTransactionEntity>> getTransactionStatus({
    required String reference,
  }) async {
    if (reference.isEmpty) {
      return Left(
        InvalidDataFailure(failureMessage: 'Payment reference cannot be empty'),
      );
    }

    return await _repository.getTransactionStatus(reference: reference);
  }

  bool _isValidEmail(String email) {
    return GetUtils.isEmail(email);
  }
}
