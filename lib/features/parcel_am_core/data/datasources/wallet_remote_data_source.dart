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
    String userId,
    double amount,
    String idempotencyKey,
  );
  Future<WalletModel> holdBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  );
  Future<WalletModel> releaseBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  );
  Future<TransactionModel> recordTransaction(
    String userId,
    double amount,
    TransactionType type,
    String? description,
    String? referenceId,
    String idempotencyKey,
  );
  Future<List<TransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  });
  Stream<List<TransactionModel>> watchTransactions(
    String userId, {
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });
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
      // Use userId as document ID for direct access
      final walletRef = firestore.collection('wallets').doc(userId);

      // Check if wallet already exists
      final existingDoc = await walletRef.get();
      if (existingDoc.exists) {
        // Wallet already exists, return it
        return WalletModel.fromFirestore(existingDoc);
      }

      // Create new wallet with userId as document ID
      final walletData = {
        'id': userId,
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
      final docSnapshot = await firestore
          .collection('wallets')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        throw const WalletNotFoundException();
      }

      return WalletModel.fromFirestore(docSnapshot);
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
          .doc(userId)
          .snapshots()
          .handleError((error) {
        Logger.logError('Firestore Error (watchWallet): $error', tag: 'WalletRemoteDataSource');
      })
          .map((snapshot) {
        if (!snapshot.exists) {
          throw const WalletNotFoundException();
        }
        return WalletModel.fromFirestore(snapshot);
      });
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<WalletModel> updateBalance(
    String userId,
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
        final walletDoc = await firestore.collection('wallets').doc(userId).get();
        return WalletModel.fromFirestore(walletDoc);
      }

      final docRef = firestore.collection('wallets').doc(userId);

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
    String userId,
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
        final walletDoc = await firestore.collection('wallets').doc(userId).get();
        return WalletModel.fromFirestore(walletDoc);
      }

      final docRef = firestore.collection('wallets').doc(userId);

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
    String userId,
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
        final walletDoc = await firestore.collection('wallets').doc(userId).get();
        return WalletModel.fromFirestore(walletDoc);
      }

      final docRef = firestore.collection('wallets').doc(userId);

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
        'walletId': userId,
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

  @override
  Future<List<TransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('funding_orders')
          .where('userId', isEqualTo: userId);

      // Apply status filter
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      // Apply date range filter
      if (startDate != null) {
        query = query.where('time_created', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('time_created', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      // Order by time
      query = query.orderBy('time_created', descending: true);

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Apply limit
      query = query.limit(limit);

      final querySnapshot = await query.get();

      // Map to transaction models
      List<TransactionModel> transactions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: doc.id,
          walletId: userId,
          userId: userId,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          type: TransactionType.deposit,
          status: _mapFundingStatus(data['status'] as String?),
          currency: 'NGN',
          timestamp: _parseTimestamp(data['time_created']),
          description: 'Wallet Funding',
          referenceId: data['reference'] as String?,
          metadata: data['metadata'] as Map<String, dynamic>? ?? {},
          idempotencyKey: doc.id,
        );
      }).toList();

      // Apply search filter if provided (client-side filtering)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        transactions = transactions.where((transaction) {
          final reference = transaction.referenceId?.toLowerCase() ?? '';
          final amount = transaction.amount.toString();
          final description = transaction.description?.toLowerCase() ?? '';
          return reference.contains(lowerQuery) ||
              amount.contains(lowerQuery) ||
              description.contains(lowerQuery);
        }).toList();
      }

      return transactions;
    } on FirebaseException catch (e) {
      Logger.logError('Failed to fetch transactions: $e', tag: 'WalletRemoteDataSource');
      throw ServerException();
    } catch (e) {
      Logger.logError('Unexpected error fetching transactions: $e', tag: 'WalletRemoteDataSource');
      throw ServerException();
    }
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(
    String userId, {
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('funding_orders')
          .where('userId', isEqualTo: userId);

      // Apply status filter
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      // Apply date range filter
      if (startDate != null) {
        query = query.where('time_created', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('time_created', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      // Order by time and limit
      query = query.orderBy('time_created', descending: true).limit(limit);

      return query.snapshots().handleError((error) {
        Logger.logError('Firestore Error (watchTransactions): $error', tag: 'WalletRemoteDataSource');
      }).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return TransactionModel(
            id: doc.id,
            walletId: userId,
            userId: userId,
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            type: TransactionType.deposit,
            status: _mapFundingStatus(data['status'] as String?),
            currency: 'NGN',
            timestamp: _parseTimestamp(data['time_created']),
            description: 'Wallet Funding',
            referenceId: data['reference'] as String?,
            metadata: data['metadata'] as Map<String, dynamic>? ?? {},
            idempotencyKey: doc.id,
          );
        }).toList();
      });
    } catch (e) {
      Logger.logError('Error creating transaction stream: $e', tag: 'WalletRemoteDataSource');
      throw ServerException();
    }
  }

  TransactionStatus _mapFundingStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
      case 'completed':
        return TransactionStatus.completed;
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
      case 'expired':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

// Extension for testing purposes - allows access to private methods in tests
extension WalletRemoteDataSourceTestExtension on WalletRemoteDataSourceImpl {
  Future<TransactionModel?> checkDuplicateTransaction(String idempotencyKey) {
    return _checkDuplicateTransaction(idempotencyKey);
  }
}
