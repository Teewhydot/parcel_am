import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/exceptions/wallet_exceptions.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../../../../core/network/network_info.dart';

class WalletRepositoryImpl implements WalletRepository {
  final remoteDataSource = GetIt.instance<WalletRemoteDataSource>();
  final networkInfo = GetIt.instance<NetworkInfo>();

  @override
  Future<Either<Failure, WalletEntity>> createWallet(
    String userId, {
    double initialBalance = 0.0,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final walletModel = await remoteDataSource.createWallet(
          userId,
          initialBalance: initialBalance,
        );
        return Right(walletModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on WalletException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> getWallet(String userId) async {
    try {
      if (await networkInfo.isConnected) {
        final walletModel = await remoteDataSource.getWallet(userId);
        return Right(walletModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on WalletNotFoundException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on WalletException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> updateBalance(
    String walletId,
    double amount,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final walletModel =
            await remoteDataSource.updateBalance(walletId, amount);
        return Right(walletModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on InsufficientBalanceException catch (e) {
      return Left(ValidationFailure(failureMessage: e.message));
    } on WalletNotFoundException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on WalletException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, WalletEntity>> watchBalance(String userId) {
    return ErrorHandler.handleStream(
      () => remoteDataSource.watchWallet(userId).map((walletModel) {
        return walletModel.toEntity();
      }),
      operationName: 'watchBalance',
    );
  }

  @override
  Future<Either<Failure, WalletEntity>> holdBalance(
    String walletId,
    double amount,
    String referenceId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final walletModel = await remoteDataSource.holdBalance(
          walletId,
          amount,
          referenceId,
        );
        return Right(walletModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on InsufficientBalanceException catch (e) {
      return Left(ValidationFailure(failureMessage: e.message));
    } on InvalidAmountException catch (e) {
      return Left(ValidationFailure(failureMessage: e.message));
    } on WalletNotFoundException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on HoldBalanceFailedException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on WalletException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> releaseBalance(
    String walletId,
    double amount,
    String referenceId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final walletModel = await remoteDataSource.releaseBalance(
          walletId,
          amount,
          referenceId,
        );
        return Right(walletModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on InvalidAmountException catch (e) {
      return Left(ValidationFailure(failureMessage: e.message));
    } on WalletNotFoundException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on ReleaseBalanceFailedException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on WalletException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> recordTransaction(
    String walletId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final wallet = await remoteDataSource.getWallet(walletId);
        final transactionModel = await remoteDataSource.recordTransaction(
          walletId,
          wallet.userId,
          amount,
          type,
          description,
          referenceId,
        );
        return Right(transactionModel.toEntity());
      } else {
        return const Left(
            NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on InvalidAmountException catch (e) {
      return Left(ValidationFailure(failureMessage: e.message));
    } on TransactionFailedException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on WalletException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Server error occurred'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }
}
