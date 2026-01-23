import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/paystack_transaction_entity.dart';
import '../../domain/repositories/paystack_payment_repository.dart';
import '../remote/data_sources/paystack_payment_data_source.dart';

class PaystackPaymentRepositoryImpl implements PaystackPaymentRepository {
  final PaystackPaymentDataSource _paystackDataSource;

  PaystackPaymentRepositoryImpl({PaystackPaymentDataSource? paystackDataSource})
      : _paystackDataSource = paystackDataSource ?? GetIt.instance<PaystackPaymentDataSource>();

  @override
  Future<Either<Failure, PaystackTransactionEntity>> initializePayment({
    required String orderId,
    required double amount,
    required String email,
    required Map<String, dynamic>? metadata,
  }) {
    return ErrorHandler.handle(
      () async {
        final result = await _paystackDataSource.initializePayment(
          orderId: orderId,
          amount: amount,
          email: email,
          metadata: metadata,
        );
        return PaystackTransactionEntity.fromJson(result);
      },
      operationName: 'initializePayment',
    );
  }

  @override
  Future<Either<Failure, PaystackTransactionEntity>> verifyPayment({
    required String reference,
    required String orderId,
  }) {
    return ErrorHandler.handle(
      () async {
        final result = await _paystackDataSource.verifyPayment(
          reference: reference,
          orderId: orderId,
        );
        return PaystackTransactionEntity.fromJson(result);
      },
      operationName: 'verifyPayment',
    );
  }

  @override
  Future<Either<Failure, PaystackTransactionEntity>> getTransactionStatus({
    required String reference,
  }) {
    return ErrorHandler.handle(
      () async {
        final result = await _paystackDataSource.getTransactionStatus(
          reference: reference,
        );
        return PaystackTransactionEntity.fromJson(result);
      },
      operationName: 'getTransactionStatus',
    );
  }
}