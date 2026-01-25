import 'dart:async';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/connectivity_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/exceptions/wallet_exceptions.dart';

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
  Future<WalletModel> clearHeldBalance(
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
  }

  @override
  Future<WalletModel> getWallet(String userId) async {
    final docSnapshot = await firestore
        .collection('wallets')
        .doc(userId)
        .get();

    if (!docSnapshot.exists) {
      throw const WalletNotFoundException();
    }

    return WalletModel.fromFirestore(docSnapshot);
  }

  @override
  Stream<WalletModel> watchWallet(String userId) {
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
  }

  @override
  Future<WalletModel> updateBalance(
    String userId,
    double amount,
    String idempotencyKey,
  ) async {
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
  }

  @override
  Future<WalletModel> holdBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
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
  }

  @override
  Future<WalletModel> releaseBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
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
  }

  @override
  Future<WalletModel> clearHeldBalance(
    String userId,
    double amount,
    String referenceId,
    String idempotencyKey,
  ) async {
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

      // Only decrement held balance - money is transferred out, not to available
      final newHeldBalance = wallet.heldBalance - amount;
      final newTotalBalance = wallet.availableBalance + newHeldBalance;

      transaction.update(docRef, {
        'heldBalance': newHeldBalance,
        'totalBalance': newTotalBalance,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });

    final updatedDoc = await docRef.get();
    return WalletModel.fromFirestore(updatedDoc);
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
    // Fetch from both funding_orders and withdrawal_orders
    final List<TransactionModel> allTransactions = [];

    // 1. Fetch funding orders (deposits)
    Query<Map<String, dynamic>> fundingQuery = firestore
        .collection('funding_orders')
        .where('userId', isEqualTo: userId);

    // Apply status filter for funding orders
    if (status != null && status.isNotEmpty) {
      final fundingStatus = _mapFilterStatusToFundingStatus(status);
      if (fundingStatus != null) {
        fundingQuery = fundingQuery.where('status', isEqualTo: fundingStatus);
      }
    }

    // Apply date range filter for funding orders
    if (startDate != null) {
      fundingQuery = fundingQuery.where('time_created', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      fundingQuery = fundingQuery.where('time_created', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    fundingQuery = fundingQuery.orderBy('time_created', descending: true).limit(limit);

    // 2. Build withdrawal orders query
    Query<Map<String, dynamic>> withdrawalQuery = firestore
        .collection('withdrawal_orders')
        .where('userId', isEqualTo: userId);

    // Apply status filter for withdrawals
    if (status != null && status.isNotEmpty) {
      final withdrawalStatus = _mapFilterStatusToWithdrawalStatus(status);
      if (withdrawalStatus != null) {
        withdrawalQuery = withdrawalQuery.where('status', isEqualTo: withdrawalStatus);
      }
    }

    // Apply date range filter for withdrawals (uses createdAt, not time_created)
    if (startDate != null) {
      withdrawalQuery = withdrawalQuery.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      withdrawalQuery = withdrawalQuery.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    withdrawalQuery = withdrawalQuery.orderBy('createdAt', descending: true).limit(limit);

    // Execute both queries in parallel for better performance
    final results = await Future.wait([
      fundingQuery.get(),
      withdrawalQuery.get(),
    ]);

    final fundingSnapshot = results[0];
    final withdrawalSnapshot = results[1];

    // Process funding transactions
    final fundingTransactions = fundingSnapshot.docs.map((doc) {
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
    allTransactions.addAll(fundingTransactions);

    // Process withdrawal transactions
    final withdrawalTransactions = withdrawalSnapshot.docs.map((doc) {
      final data = doc.data();
      return TransactionModel(
        id: doc.id,
        walletId: userId,
        userId: userId,
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        type: TransactionType.withdrawal,
        status: _mapWithdrawalStatus(data['status'] as String?),
        currency: 'NGN',
        timestamp: _parseTimestamp(data['createdAt']),
        description: 'Withdrawal to ${_getBankName(data)}',
        referenceId: doc.id,
        metadata: data['metadata'] as Map<String, dynamic>? ?? {},
        idempotencyKey: doc.id,
      );
    }).toList();
    allTransactions.addAll(withdrawalTransactions);

    // 3. Sort all transactions by timestamp (descending)
    allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 4. Apply limit after merging
    List<TransactionModel> transactions = allTransactions.take(limit).toList();

    // 5. Apply search filter if provided (client-side filtering)
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
  }

  /// Extract bank name from withdrawal data
  String _getBankName(Map<String, dynamic> data) {
    final bankAccount = data['bankAccount'] as Map<String, dynamic>?;
    return bankAccount?['bankName'] as String? ?? 'Bank';
  }

  /// Map filter status to funding order status
  String? _mapFilterStatusToFundingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return 'confirmed';
      case 'pending':
        return 'pending';
      case 'failed':
        return 'failed';
      default:
        return null; // Return null to not filter
    }
  }

  /// Map filter status to withdrawal order status
  String? _mapFilterStatusToWithdrawalStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return 'success';
      case 'pending':
        return 'pending';
      case 'failed':
        return 'failed';
      default:
        return null; // Return null to not filter
    }
  }

  /// Map withdrawal status string to TransactionStatus
  TransactionStatus _mapWithdrawalStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return TransactionStatus.completed;
      case 'pending':
      case 'processing':
        return TransactionStatus.pending;
      case 'failed':
      case 'reversed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
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
    // Build funding orders query
    Query<Map<String, dynamic>> fundingQuery = firestore
        .collection('funding_orders')
        .where('userId', isEqualTo: userId);

    // Apply status filter for funding orders
    if (status != null && status.isNotEmpty) {
      final fundingStatus = _mapFilterStatusToFundingStatus(status);
      if (fundingStatus != null) {
        fundingQuery = fundingQuery.where('status', isEqualTo: fundingStatus);
      }
    }

    // Apply date range filter for funding orders
    if (startDate != null) {
      fundingQuery = fundingQuery.where('time_created', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      fundingQuery = fundingQuery.where('time_created', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    fundingQuery = fundingQuery.orderBy('time_created', descending: true).limit(limit);

    // Build withdrawal orders query
    Query<Map<String, dynamic>> withdrawalQuery = firestore
        .collection('withdrawal_orders')
        .where('userId', isEqualTo: userId);

    // Apply status filter for withdrawals
    if (status != null && status.isNotEmpty) {
      final withdrawalStatus = _mapFilterStatusToWithdrawalStatus(status);
      if (withdrawalStatus != null) {
        withdrawalQuery = withdrawalQuery.where('status', isEqualTo: withdrawalStatus);
      }
    }

    // Apply date range filter for withdrawals
    if (startDate != null) {
      withdrawalQuery = withdrawalQuery.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      withdrawalQuery = withdrawalQuery.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    withdrawalQuery = withdrawalQuery.orderBy('createdAt', descending: true).limit(limit);

    // Combine both streams
    final fundingStream = fundingQuery.snapshots().handleError((error) {
      Logger.logError('Firestore Error (watchFundingOrders): $error', tag: 'WalletRemoteDataSource');
    });

    final withdrawalStream = withdrawalQuery.snapshots().handleError((error) {
      Logger.logError('Firestore Error (watchWithdrawalOrders): $error', tag: 'WalletRemoteDataSource');
    });

    // Use combineLatest to merge both streams
    return _combineTransactionStreams(
      fundingStream,
      withdrawalStream,
      userId,
      limit,
    );
  }

  /// Combines funding and withdrawal streams into a single sorted stream
  Stream<List<TransactionModel>> _combineTransactionStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>> fundingStream,
    Stream<QuerySnapshot<Map<String, dynamic>>> withdrawalStream,
    String userId,
    int limit,
  ) {
    List<TransactionModel> lastFundingTransactions = [];
    List<TransactionModel> lastWithdrawalTransactions = [];

    // Create a stream controller to emit combined results
    final controller = StreamController<List<TransactionModel>>();

    // Track subscriptions for cleanup
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? fundingSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? withdrawalSub;

    void emitCombined() {
      final allTransactions = <TransactionModel>[
        ...lastFundingTransactions,
        ...lastWithdrawalTransactions,
      ];
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      controller.add(allTransactions.take(limit).toList());
    }

    fundingSub = fundingStream.listen((snapshot) {
      lastFundingTransactions = snapshot.docs.map((doc) {
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
      emitCombined();
    }, onError: (error) {
      Logger.logError('Funding stream error: $error', tag: 'WalletRemoteDataSource');
    });

    withdrawalSub = withdrawalStream.listen((snapshot) {
      lastWithdrawalTransactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: doc.id,
          walletId: userId,
          userId: userId,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          type: TransactionType.withdrawal,
          status: _mapWithdrawalStatus(data['status'] as String?),
          currency: 'NGN',
          timestamp: _parseTimestamp(data['createdAt']),
          description: 'Withdrawal to ${_getBankName(data)}',
          referenceId: doc.id,
          metadata: data['metadata'] as Map<String, dynamic>? ?? {},
          idempotencyKey: doc.id,
        );
      }).toList();
      emitCombined();
    }, onError: (error) {
      Logger.logError('Withdrawal stream error: $error', tag: 'WalletRemoteDataSource');
    });

    // Clean up when the stream is cancelled
    controller.onCancel = () {
      fundingSub?.cancel();
      withdrawalSub?.cancel();
    };

    return controller.stream;
  }

  TransactionStatus _mapFundingStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'confirmed':
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
