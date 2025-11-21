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
    String walletId,
    double amount,
  ) {
    return walletRepo.updateBalance(walletId, amount);
  }

  Stream<Either<Failure, WalletEntity>> watchBalance(String userId) {
    return walletRepo.watchBalance(userId);
  }

  Future<Either<Failure, WalletEntity>> holdBalance(
    String walletId,
    double amount,
    String referenceId,
  ) {
    return walletRepo.holdBalance(walletId, amount, referenceId);
  }

  Future<Either<Failure, WalletEntity>> releaseBalance(
    String walletId,
    double amount,
    String referenceId,
  ) {
    return walletRepo.releaseBalance(walletId, amount, referenceId);
  }

  Future<Either<Failure, TransactionEntity>> recordTransaction(
    String walletId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
  ) {
    return walletRepo.recordTransaction(
      walletId,
      amount,
      type,
      description,
      referenceId,
    );
  }
}
