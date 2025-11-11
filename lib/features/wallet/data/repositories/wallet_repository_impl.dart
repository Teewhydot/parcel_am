import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:parcel_am/features/wallet/domain/entities/wallet.dart';
import 'package:parcel_am/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Wallet>> getWallet(String userId) async {
    try {
      final wallet = await remoteDataSource.getWallet(userId);
      return Right(wallet);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createWallet(String userId) async {
    try {
      await remoteDataSource.createWallet(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBalance(
    String userId,
    double availableBalance,
    double pendingBalance,
  ) async {
    try {
      await remoteDataSource.updateBalance(
        userId,
        availableBalance,
        pendingBalance,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Wallet>> watchWallet(String userId) {
    try {
      return remoteDataSource.watchWallet(userId).map(
            (wallet) => Right<Failure, Wallet>(wallet),
          );
    } catch (e) {
      return Stream.value(
        Left(ServerFailure(failureMessage: e.toString())),
      );
    }
  }
}
