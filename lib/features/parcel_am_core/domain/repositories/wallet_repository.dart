import 'package:dartz/dartz.dart';
import '../entities/wallet_entity.dart';
import '../entities/transaction_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletEntity>> createWallet(
    String userId, {
    double initialBalance,
  });

  Future<Either<Failure, WalletEntity>> getWallet(String userId);

  Future<Either<Failure, WalletEntity>> updateBalance(
    String walletId,
    double amount,
    String idempotencyKey,
  );

  Stream<Either<Failure, WalletEntity>> watchBalance(String userId);

  Future<Either<Failure, WalletEntity>> holdBalance(
    String walletId,
    double amount,
    String referenceId,
    String idempotencyKey,
  );

  Future<Either<Failure, WalletEntity>> releaseBalance(
    String walletId,
    double amount,
    String referenceId,
    String idempotencyKey,
  );

  Future<Either<Failure, TransactionEntity>> recordTransaction(
    String walletId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
    String idempotencyKey,
  );
}
