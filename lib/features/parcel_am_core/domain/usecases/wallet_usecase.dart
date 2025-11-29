import 'package:dartz/dartz.dart';
import 'package:parcel_am/features/parcel_am_core/data/repositories/wallet_repository_impl.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../entities/transaction_entity.dart';

class WalletUseCase {
  final walletRepo  = WalletRepositoryImpl();

  Future<Either<Failure, WalletEntity>> createWallet(
    String userId, {
    double initialBalance = 0.0,
  }) {
    return walletRepo.createWallet(userId, initialBalance: initialBalance);
  }

  Future<Either<Failure, WalletEntity>> getWallet(String userId) {
    return walletRepo.getWallet(userId);
  }

  Future<Either<Failure, WalletEntity>> updateBalance(
    String userId,
    double amount,
    String idempotencyKey,
  ) {
    return walletRepo.updateBalance(userId, amount, idempotencyKey);
  }

  Stream<Either<Failure, WalletEntity>> watchBalance(String userId) {
    return walletRepo.watchBalance(userId);
  }

  Future<Either<Failure, WalletEntity>> holdBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) {
    return walletRepo.holdBalance(userId, amount, referenceId, idempotencyKey);
  }

  Future<Either<Failure, WalletEntity>> releaseBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) {
    return walletRepo.releaseBalance(userId, amount, referenceId, idempotencyKey);
  }

  Future<Either<Failure, TransactionEntity>> recordTransaction(
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
    String idempotencyKey,
  ) {
    return walletRepo.recordTransaction(
      userId,
      amount,
      type,
      description,
      referenceId,
      idempotencyKey,
    );
  }

  Future<Either<Failure, List<TransactionEntity>>> getTransactions(
    String userId, {
    int limit = 20,
  }) {
    return walletRepo.getTransactions(userId, limit: limit);
  }
}
