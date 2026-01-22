import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/exceptions/wallet_exceptions.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl({WalletRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<WalletRemoteDataSource>();

  @override
  Future<Either<Failure, WalletEntity>> createWallet(
    String userId, {
    double initialBalance = 0.0,
  }) async {
    try {
     final walletModel = await _remoteDataSource.createWallet(
          userId,
          initialBalance: initialBalance,
        );
        return Right(walletModel.toEntity());
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
      final walletModel = await _remoteDataSource.getWallet(userId);
        return Right(walletModel.toEntity());
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
    String userId,
    double amount,
    String idempotencyKey,
  ) async {
    try {
     final walletModel = await _remoteDataSource.updateBalance(
          userId,
          amount,
          idempotencyKey,
        );
        return Right(walletModel.toEntity());
    } on NoInternetException {
      return const Left(NoInternetFailure(
        failureMessage: 'No internet connection. Please check your connection and try again.',
      ));
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
      () => _remoteDataSource.watchWallet(userId).map((walletModel) {
        return walletModel.toEntity();
      }),
      operationName: 'watchBalance',
    );
  }

  @override
  Future<Either<Failure, WalletEntity>> holdBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
    try {
      final walletModel = await _remoteDataSource.holdBalance(
        userId,
        amount,
        referenceId,
        idempotencyKey,
      );
      return Right(walletModel.toEntity());
    } on NoInternetException {
      return const Left(NoInternetFailure(
        failureMessage: 'No internet connection. Please check your connection and try again.',
      ));
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
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
    try {
     final walletModel = await _remoteDataSource.releaseBalance(
          userId,
          amount,
          referenceId,
          idempotencyKey,
        );
        return Right(walletModel.toEntity());
    } on NoInternetException {
      return const Left(NoInternetFailure(
        failureMessage: 'No internet connection. Please check your connection and try again.',
      ));
    } on InsufficientHeldBalanceException catch (e) {
      return Left(ValidationFailure(failureMessage: e.message));
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
  Future<Either<Failure, WalletEntity>> clearHeldBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
    try {
      final walletModel = await _remoteDataSource.clearHeldBalance(
        userId,
        amount,
        referenceId,
        idempotencyKey,
      );
      return Right(walletModel.toEntity());
    } on NoInternetException {
      return const Left(NoInternetFailure(
        failureMessage: 'No internet connection. Please check your connection and try again.',
      ));
    } on InsufficientHeldBalanceException catch (e) {
      return Left(ValidationFailure(failureMessage: e.message));
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
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
    String idempotencyKey,
  ) async {
    try {
        final transactionModel = await _remoteDataSource.recordTransaction(
          userId,
          amount,
          type,
          description,
          referenceId,
          idempotencyKey,
        );
        return Right(transactionModel.toEntity());
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

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    TransactionFilter? filter,
  }) async {
    try {
      final transactions = await _remoteDataSource.getTransactions(
        userId,
        limit: limit,
        startAfter: startAfter,
        status: filter?.status,
        startDate: filter?.startDate,
        endDate: filter?.endDate,
        searchQuery: filter?.searchQuery,
      );
      return Right(transactions.map((t) => t.toEntity()).toList());
    } on ServerException {
      return const Left(ServerFailure(failureMessage: 'Failed to fetch transactions'));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions(
    String userId, {
    int limit = 20,
    TransactionFilter? filter,
  }) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchTransactions(
        userId,
        limit: limit,
        status: filter?.status,
        startDate: filter?.startDate,
        endDate: filter?.endDate,
      ).map((transactions) {
        return transactions.map((t) => t.toEntity()).toList();
      }),
      operationName: 'watchTransactions',
    );
  }
}
