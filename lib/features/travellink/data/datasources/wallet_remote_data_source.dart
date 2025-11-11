import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/exceptions/wallet_exceptions.dart';
import '../../domain/exceptions/custom_exceptions.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet(String userId);
  Stream<WalletModel> watchWallet(String userId);
  Future<WalletModel> updateBalance(String walletId, double amount);
  Future<WalletModel> holdBalance(
    String walletId,
    double amount,
    String referenceId,
  );
  Future<WalletModel> releaseBalance(
    String walletId,
    double amount,
    String referenceId,
  );
  Future<TransactionModel> recordTransaction(
    String walletId,
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
  );
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final FirebaseFirestore firestore;

  WalletRemoteDataSourceImpl({required this.firestore});

  @override
  Future<WalletModel> getWallet(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw const WalletNotFoundException();
      }

      return WalletModel.fromFirestore(querySnapshot.docs.first);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      if (e is WalletException) rethrow;
      throw ServerException();
    }
  }

  @override
  Stream<WalletModel> watchWallet(String userId) {
    try {
      return firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          throw const WalletNotFoundException();
        }
        return WalletModel.fromFirestore(snapshot.docs.first);
      });
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<WalletModel> updateBalance(String walletId, double amount) async {
    try {
      final docRef = firestore.collection('wallets').doc(walletId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw const WalletNotFoundException();
        }

        final wallet = WalletModel.fromFirestore(snapshot);
        final newAvailableBalance = wallet.availableBalance + amount;

        if (newAvailableBalance < 0) {
          throw const InsufficientBalanceException();
        }

        final newTotalBalance = newAvailableBalance + wallet.heldBalance;

        transaction.update(docRef, {
          'availableBalance': newAvailableBalance,
          'totalBalance': newTotalBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      final updatedDoc = await docRef.get();
      return WalletModel.fromFirestore(updatedDoc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      if (e is WalletException) rethrow;
      throw ServerException();
    }
  }

  @override
  Future<WalletModel> holdBalance(
    String walletId,
    double amount,
    String referenceId,
  ) async {
    try {
      if (amount <= 0) {
        throw const InvalidAmountException();
      }

      final docRef = firestore.collection('wallets').doc(walletId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw const WalletNotFoundException();
        }

        final wallet = WalletModel.fromFirestore(snapshot);

        if (wallet.availableBalance < amount) {
          throw const InsufficientBalanceException();
        }

        final newAvailableBalance = wallet.availableBalance - amount;
        final newHeldBalance = wallet.heldBalance + amount;

        transaction.update(docRef, {
          'availableBalance': newAvailableBalance,
          'heldBalance': newHeldBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      final updatedDoc = await docRef.get();
      return WalletModel.fromFirestore(updatedDoc);
    } on FirebaseException {
      throw const HoldBalanceFailedException();
    } catch (e) {
      if (e is WalletException) rethrow;
      throw const HoldBalanceFailedException();
    }
  }

  @override
  Future<WalletModel> releaseBalance(
    String walletId,
    double amount,
    String referenceId,
  ) async {
    try {
      if (amount <= 0) {
        throw const InvalidAmountException();
      }

      final docRef = firestore.collection('wallets').doc(walletId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw const WalletNotFoundException();
        }

        final wallet = WalletModel.fromFirestore(snapshot);

        if (wallet.heldBalance < amount) {
          throw const ReleaseBalanceFailedException(
              'Insufficient held balance');
        }

        final newAvailableBalance = wallet.availableBalance + amount;
        final newHeldBalance = wallet.heldBalance - amount;

        transaction.update(docRef, {
          'availableBalance': newAvailableBalance,
          'heldBalance': newHeldBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      final updatedDoc = await docRef.get();
      return WalletModel.fromFirestore(updatedDoc);
    } on FirebaseException {
      throw const ReleaseBalanceFailedException();
    } catch (e) {
      if (e is WalletException) rethrow;
      throw const ReleaseBalanceFailedException();
    }
  }

  @override
  Future<TransactionModel> recordTransaction(
    String walletId,
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
  ) async {
    try {
      if (amount <= 0) {
        throw const InvalidAmountException();
      }

      final transactionRef = firestore.collection('transactions').doc();

      final transactionData = {
        'walletId': walletId,
        'userId': userId,
        'amount': amount,
        'type': type.name,
        'status': TransactionStatus.completed.name,
        'currency': 'USD',
        'timestamp': FieldValue.serverTimestamp(),
        'description': description,
        'referenceId': referenceId,
        'metadata': {},
      };

      await transactionRef.set(transactionData);

      final createdDoc = await transactionRef.get();
      return TransactionModel.fromFirestore(createdDoc);
    } on FirebaseException {
      throw const TransactionFailedException();
    } catch (e) {
      if (e is WalletException) rethrow;
      throw const TransactionFailedException();
    }
  }
}
