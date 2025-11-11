import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/features/wallet/domain/entities/wallet.dart';

abstract class WalletRepository {
  Future<Either<Failure, Wallet>> getWallet(String userId);
  Future<Either<Failure, void>> createWallet(String userId);
  Future<Either<Failure, void>> updateBalance(
    String userId,
    double availableBalance,
    double pendingBalance,
  );
  Stream<Either<Failure, Wallet>> watchWallet(String userId);
}
