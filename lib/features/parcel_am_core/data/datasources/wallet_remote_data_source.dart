import 'dart:async';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/connectivity_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/exceptions/wallet_exceptions.dart';
import '../../domain/exceptions/custom_exceptions.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> createWallet(String userId, {double initialBalance = 0.0});
  Future<WalletModel> getWallet(String userId);
  Stream<WalletModel> watchWallet(String userId);
  Future<WalletModel> updateBalance(
    String walletId,
    double amount,
    String idempotencyKey,
  );
  Future<WalletModel> holdBalance(
    String walletId,
    double amount,
    String referenceId,
    String idempotencyKey,
  );
  Future<WalletModel> releaseBalance(
    String walletId,
    double amount,
    String referenceId,
    String idempotencyKey,
  );
  Future<TransactionModel> recordTransaction(
    String walletId,
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
    String idempotencyKey,
  );
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final FirebaseFirestore firestore;
  final ConnectivityService connectivityService;

  WalletRemoteDataSourceImpl({
    required this.firestore,
    required this.connectivityService,
  });

  /// Checks for connectivity and throws NoInternetException if offline
  Future<void> _validateConnectivity() async {
    final isConnected = await connectivityService.checkConnection();
    if (!isConnected) {
      throw NoInternetException();
    }
  }

  /// Checks for duplicate transaction by idempotencyKey
  /// Returns existing transaction if found with completed status
  Future<TransactionModel?> _checkDuplicateTransaction(String idempotencyKey) async {
    try {
      final querySnapshot = await firestore
          .collection('transactions')
          .where('idempotencyKey', isEqualTo: idempotencyKey)
          .where('status', isEqualTo: TransactionStatus.completed.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TransactionModel.fromFirestore(querySnapshot.docs.first);
      }

      return null;
    } catch (e) {
      // If query fails, proceed with transaction (no duplicate found)
      return null;
    }
  }

  @override
  Future<WalletModel> createWallet(String userId, {double initialBalance = 0.0}) async {
    try {
      // Check if wallet already exists
      final existingWalletQuery = await firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingWalletQuery.docs.isNotEmpty) {
        // Wallet already exists, return it
        return WalletModel.fromFirestore(existingWalletQuery.docs.first);
      }

      // Create new wallet
      final walletRef = firestore.collection('wallets').doc();
      final walletData = {
        'id': walletRef.id,
        'userId': userId,
        'availableBalance': initialBalance,
        'heldBalance': 0.0,
        'totalBalance': initialBalance,
        'currency': 'NGN',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await walletRef.set(walletData);

      final createdDoc = await walletRef.get();
      return WalletModel.fromFirestore(createdDoc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      if (e is WalletException) rethrow;
      throw ServerException();
    }
  }

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
          .handleError((error) {
        Logger.logError('Firestore Error (watchWallet): $error', tag: 'WalletRemoteDataSource');
      })
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
  Future<WalletModel> updateBalance(
    String walletId,
    double amount,
    String idempotencyKey,
  ) async {
    try {
      // Validate connectivity
      await _validateConnectivity();

      // Check for duplicate transaction
      final duplicate = await _checkDuplicateTransaction(idempotencyKey);
      if (duplicate != null) {
        // Return wallet in current state for duplicate transaction
        final walletDoc = await firestore.collection('wallets').doc(walletId).get();
        return WalletModel.fromFirestore(walletDoc);
      }

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
      if (e is NoInternetException) rethrow;
      throw ServerException();
    }
  }

  @override
  Future<WalletModel> holdBalance(
    String walletId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
    try {
      // Validate connectivity
      await _validateConnectivity();

      if (amount <= 0) {
        throw const InvalidAmountException();
      }

      // Check for duplicate transaction
      final duplicate = await _checkDuplicateTransaction(idempotencyKey);
      if (duplicate != null) {
        // Return wallet in current state for duplicate transaction
        final walletDoc = await firestore.collection('wallets').doc(walletId).get();
        return WalletModel.fromFirestore(walletDoc);
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
      if (e is NoInternetException) rethrow;
      throw const HoldBalanceFailedException();
    }
  }

  @override
  Future<WalletModel> releaseBalance(
    String walletId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
    try {
      // Validate connectivity
      await _validateConnectivity();

      if (amount <= 0) {
        throw const InvalidAmountException();
      }

      // Check for duplicate transaction
      final duplicate = await _checkDuplicateTransaction(idempotencyKey);
      if (duplicate != null) {
        // Return wallet in current state for duplicate transaction
        final walletDoc = await firestore.collection('wallets').doc(walletId).get();
        return WalletModel.fromFirestore(walletDoc);
      }

      final docRef = firestore.collection('wallets').doc(walletId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw const WalletNotFoundException();
        }

        final wallet = WalletModel.fromFirestore(snapshot);

        if (wallet.heldBalance < amount) {
          throw InsufficientHeldBalanceException(
            required: amount,
            available: wallet.heldBalance,
          );
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
      if (e is NoInternetException) rethrow;
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
    String idempotencyKey,
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
        'idempotencyKey': idempotencyKey,
        'ttl': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
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

// Extension for testing purposes - allows access to private methods in tests
extension WalletRemoteDataSourceTestExtension on WalletRemoteDataSourceImpl {
  Future<TransactionModel?> checkDuplicateTransaction(String idempotencyKey) {
    return _checkDuplicateTransaction(idempotencyKey);
  }
}
