import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl({WalletRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<WalletRemoteDataSource>();

  @override
  Future<Either<Failure, WalletEntity>> createWallet(
    String userId, {
    double initialBalance = 0.0,
  }) {
    return ErrorHandler.handle(
      () async {
        final walletModel = await _remoteDataSource.createWallet(
          userId,
          initialBalance: initialBalance,
        );
        return walletModel.toEntity();
      },
      operationName: 'createWallet',
    );
  }

  @override
  Future<Either<Failure, WalletEntity>> getWallet(String userId) {
    return ErrorHandler.handle(
      () async {
        final walletModel = await _remoteDataSource.getWallet(userId);
        return walletModel.toEntity();
      },
      operationName: 'getWallet',
    );
  }

  @override
  Future<Either<Failure, WalletEntity>> updateBalance(
    String userId,
    double amount,
    String idempotencyKey,
  ) {
    return ErrorHandler.handle(
      () async {
        final walletModel = await _remoteDataSource.updateBalance(
          userId,
          amount,
          idempotencyKey,
        );
        return walletModel.toEntity();
      },
      operationName: 'updateBalance',
    );
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
  ) {
    return ErrorHandler.handle(
      () async {
        final walletModel = await _remoteDataSource.holdBalance(
          userId,
          amount,
          referenceId,
          idempotencyKey,
        );
        return walletModel.toEntity();
      },
      operationName: 'holdBalance',
    );
  }

  @override
  Future<Either<Failure, WalletEntity>> releaseBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) {
    return ErrorHandler.handle(
      () async {
        final walletModel = await _remoteDataSource.releaseBalance(
          userId,
          amount,
          referenceId,
          idempotencyKey,
        );
        return walletModel.toEntity();
      },
      operationName: 'releaseBalance',
    );
  }

  @override
  Future<Either<Failure, WalletEntity>> clearHeldBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) {
    return ErrorHandler.handle(
      () async {
        final walletModel = await _remoteDataSource.clearHeldBalance(
          userId,
          amount,
          referenceId,
          idempotencyKey,
        );
        return walletModel.toEntity();
      },
      operationName: 'clearHeldBalance',
    );
  }

  @override
  Future<Either<Failure, TransactionEntity>> recordTransaction(
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
    String idempotencyKey,
  ) {
    return ErrorHandler.handle(
      () async {
        final transactionModel = await _remoteDataSource.recordTransaction(
          userId,
          amount,
          type,
          description,
          referenceId,
          idempotencyKey,
        );
        return transactionModel.toEntity();
      },
      operationName: 'recordTransaction',
    );
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    TransactionFilter? filter,
  }) {
    return ErrorHandler.handle(
      () async {
        final transactions = await _remoteDataSource.getTransactions(
          userId,
          limit: limit,
          startAfter: startAfter,
          status: filter?.status,
          startDate: filter?.startDate,
          endDate: filter?.endDate,
          searchQuery: filter?.searchQuery,
        );
        return transactions.map((t) => t.toEntity()).toList();
      },
      operationName: 'getTransactions',
    );
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
