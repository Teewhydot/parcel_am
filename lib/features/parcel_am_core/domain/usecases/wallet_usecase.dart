import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../entities/transaction_entity.dart';
import '../repositories/wallet_repository.dart';
import '../value_objects/transaction_filter.dart';

class WalletUseCase {
  final WalletRepository _repository;

  WalletUseCase({WalletRepository? repository})
      : _repository = repository ?? GetIt.instance<WalletRepository>();

  Future<Either<Failure, WalletEntity>> createWallet(
    String userId, {
    double initialBalance = 0.0,
  }) {
    return _repository.createWallet(userId, initialBalance: initialBalance);
  }

  Future<Either<Failure, WalletEntity>> getWallet(String userId) {
    return _repository.getWallet(userId);
  }

  Future<Either<Failure, WalletEntity>> updateBalance(
    String userId,
    double amount,
    String idempotencyKey,
  ) {
    return _repository.updateBalance(userId, amount, idempotencyKey);
  }

  Stream<Either<Failure, WalletEntity>> watchBalance(String userId) {
    return _repository.watchBalance(userId);
  }

  Future<Either<Failure, WalletEntity>> holdBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) {
    return _repository.holdBalance(userId, amount, referenceId, idempotencyKey);
  }

  Future<Either<Failure, WalletEntity>> releaseBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) {
    return _repository.releaseBalance(userId, amount, referenceId, idempotencyKey);
  }

  Future<Either<Failure, WalletEntity>> clearHeldBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) {
    return _repository.clearHeldBalance(userId, amount, referenceId, idempotencyKey);
  }

  Future<Either<Failure, TransactionEntity>> recordTransaction(
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
    String idempotencyKey,
  ) {
    return _repository.recordTransaction(
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
    DocumentSnapshot? startAfter,
    TransactionFilter? filter,
  }) {
    return _repository.getTransactions(
      userId,
      limit: limit,
      startAfter: startAfter,
      filter: filter,
    );
  }

  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions(
    String userId, {
    int limit = 20,
    TransactionFilter? filter,
  }) {
    return _repository.watchTransactions(
      userId,
      limit: limit,
      filter: filter,
    );
  }
}
