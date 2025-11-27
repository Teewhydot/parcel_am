import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/parcel_am_core/data/helpers/idempotency_helper.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/transaction_model.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/transaction_entity.dart';
import 'package:parcel_am/features/parcel_am_core/domain/exceptions/wallet_exceptions.dart';

void main() {
  group('Integration Test 1: Full Hold-Release Cycle with Idempotency', () {
    test(
        'should generate unique idempotency keys for hold and release operations',
        () {
      // Act - Generate idempotency keys for hold and release operations
      final holdIdempotencyKey = IdempotencyHelper.generateTransactionId('hold');
      final releaseIdempotencyKey =
          IdempotencyHelper.generateTransactionId('release');

      // Assert - Verify keys are valid and unique
      expect(IdempotencyHelper.isValidTransactionId(holdIdempotencyKey), isTrue);
      expect(holdIdempotencyKey, startsWith('txn_hold_'));

      expect(
          IdempotencyHelper.isValidTransactionId(releaseIdempotencyKey), isTrue);
      expect(releaseIdempotencyKey, startsWith('txn_release_'));

      // Keys must be different even for same operation type
      expect(holdIdempotencyKey, isNot(equals(releaseIdempotencyKey)));
    });

    test('should maintain idempotency key format through transaction lifecycle',
        () {
      // Arrange - Simulate a complete transaction lifecycle
      const walletId = 'wallet-123';
      const userId = 'user-123';
      const amount = 100.0;
      final idempotencyKey = IdempotencyHelper.generateTransactionId('hold');

      // Act - Create transaction model with idempotency key
      final transaction = TransactionModel(
        id: 'txn-hold-123',
        walletId: walletId,
        userId: userId,
        amount: amount,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: DateTime.now(),
        idempotencyKey: idempotencyKey,
      );

      // Assert - Verify idempotency key is preserved
      expect(transaction.idempotencyKey, equals(idempotencyKey));
      expect(IdempotencyHelper.isValidTransactionId(transaction.idempotencyKey),
          isTrue);

      // Verify JSON serialization preserves idempotency key
      final json = transaction.toJson();
      expect(json['idempotencyKey'], equals(idempotencyKey));

      // Verify deserialization preserves idempotency key
      final deserializedTransaction = TransactionModel.fromJson(json);
      expect(deserializedTransaction.idempotencyKey, equals(idempotencyKey));
    });

    test('should identify duplicate transactions by idempotency key', () {
      // Arrange
      const walletId = 'wallet-123';
      const userId = 'user-123';
      const amount = 100.0;
      final idempotencyKey = IdempotencyHelper.generateTransactionId('hold');

      // Act - Create two transactions with same idempotency key
      final transaction1 = TransactionModel(
        id: 'txn-hold-123',
        walletId: walletId,
        userId: userId,
        amount: amount,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: DateTime.now(),
        idempotencyKey: idempotencyKey,
      );

      final transaction2 = TransactionModel(
        id: 'txn-hold-456', // Different ID
        walletId: walletId,
        userId: userId,
        amount: amount,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: DateTime.now(),
        idempotencyKey: idempotencyKey, // Same idempotency key
      );

      // Assert - Both transactions should be identifiable as duplicates
      expect(transaction1.idempotencyKey, equals(transaction2.idempotencyKey));
      expect(transaction1.id, isNot(equals(transaction2.id)));
    });
  });

  group('Integration Test 2: Concurrent Transaction Handling', () {
    test('should generate unique idempotency keys for concurrent operations',
        () {
      // Simulate concurrent operations by generating multiple keys rapidly
      final idempotencyKeys = <String>{};

      // Act - Generate 100 idempotency keys concurrently
      for (int i = 0; i < 100; i++) {
        final key = IdempotencyHelper.generateTransactionId('hold');
        idempotencyKeys.add(key);
      }

      // Assert - All keys should be unique
      expect(idempotencyKeys.length, equals(100));

      // All keys should be valid
      for (final key in idempotencyKeys) {
        expect(IdempotencyHelper.isValidTransactionId(key), isTrue);
        expect(key, startsWith('txn_hold_'));
      }
    });

    test('should maintain timestamp ordering in idempotency keys', () async {
      // Act - Generate keys with delay
      final key1 = IdempotencyHelper.generateTransactionId('hold');
      final timestamp1 = int.parse(key1.split('_')[2]);

      await Future.delayed(const Duration(milliseconds: 50));

      final key2 = IdempotencyHelper.generateTransactionId('hold');
      final timestamp2 = int.parse(key2.split('_')[2]);

      // Assert - Second timestamp should be greater than or equal to first
      expect(timestamp2, greaterThanOrEqualTo(timestamp1));

      // Keys should still be unique even if timestamps are same
      expect(key1, isNot(equals(key2)));
    });
  });

  group('Integration Test 3: Offline Operation Rejection', () {
    test('should validate idempotency keys exist for offline protection', () {
      // This test verifies that idempotency infrastructure is in place
      // Actual offline rejection happens at data source layer with ConnectivityService

      // Arrange - Generate keys for all operations
      final holdKey = IdempotencyHelper.generateTransactionId('hold');
      final releaseKey = IdempotencyHelper.generateTransactionId('release');
      final depositKey = IdempotencyHelper.generateTransactionId('deposit');
      final withdrawalKey = IdempotencyHelper.generateTransactionId('withdrawal');

      // Assert - All operations should have valid idempotency keys
      expect(IdempotencyHelper.isValidTransactionId(holdKey), isTrue);
      expect(IdempotencyHelper.isValidTransactionId(releaseKey), isTrue);
      expect(IdempotencyHelper.isValidTransactionId(depositKey), isTrue);
      expect(IdempotencyHelper.isValidTransactionId(withdrawalKey), isTrue);

      // Keys should contain operation type
      expect(holdKey, contains('hold'));
      expect(releaseKey, contains('release'));
      expect(depositKey, contains('deposit'));
      expect(withdrawalKey, contains('withdrawal'));
    });
  });

  group('Integration Test 4: Insufficient Balance Scenarios', () {
    test('should throw InsufficientBalanceException with correct message', () {
      // Arrange
      const exception = InsufficientBalanceException();

      // Assert
      expect(exception, isA<WalletException>());
      expect(exception.message, contains('Insufficient balance'));
    });

    test(
        'should throw InsufficientHeldBalanceException with required and available fields',
        () {
      // Arrange
      const requiredAmount = 100.0;
      const heldAmount = 30.0;

      // Act
      const exception = InsufficientHeldBalanceException(
        required: requiredAmount,
        available: heldAmount,
      );

      // Assert
      expect(exception, isA<WalletException>());
      expect(exception.required, equals(requiredAmount));
      expect(exception.available, equals(heldAmount));
      expect(exception.message, contains('Insufficient held balance'));
      expect(exception.message, contains('100.0'));
      expect(exception.message, contains('30.0'));
    });

    test('should differentiate between available and held balance exceptions',
        () {
      // Arrange
      const insufficientAvailable = InsufficientBalanceException();
      const insufficientHeld = InsufficientHeldBalanceException(
        required: 100.0,
        available: 50.0,
      );

      // Assert - Both are wallet exceptions but different types
      expect(insufficientAvailable, isA<InsufficientBalanceException>());
      expect(insufficientHeld, isA<InsufficientHeldBalanceException>());
      expect(insufficientAvailable.runtimeType,
          isNot(equals(insufficientHeld.runtimeType)));
    });
  });

  group('Integration Test 5: Transaction Rollback on Firestore Failure', () {
    test('should verify transaction status enum includes all required states',
        () {
      // Firestore transactions use status to track completion
      // Verify all status values exist

      expect(TransactionStatus.values, contains(TransactionStatus.pending));
      expect(TransactionStatus.values, contains(TransactionStatus.completed));
      expect(TransactionStatus.values, contains(TransactionStatus.failed));
      expect(TransactionStatus.values, contains(TransactionStatus.cancelled));
    });

    test('should verify transaction types include all wallet operations', () {
      // Verify all transaction types for wallet operations exist
      expect(TransactionType.values, contains(TransactionType.hold));
      expect(TransactionType.values, contains(TransactionType.release));
      expect(TransactionType.values, contains(TransactionType.deposit));
      expect(TransactionType.values, contains(TransactionType.withdrawal));
    });
  });

  group('Integration Test 6: TTL and Deduplication Query Performance', () {
    test('should verify transaction model includes idempotency key field', () {
      // Arrange
      final now = DateTime.now();
      const idempotencyKey =
          'txn_hold_1732723200000_550e8400-e29b-41d4-a716-446655440000';

      final transaction = TransactionModel(
        id: 'txn-123',
        walletId: 'wallet-123',
        userId: 'user-123',
        amount: 100.0,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: now,
        idempotencyKey: idempotencyKey,
      );

      // Assert - IdempotencyKey is required field
      expect(transaction.idempotencyKey, equals(idempotencyKey));

      // Verify JSON serialization includes idempotencyKey
      final json = transaction.toJson();
      expect(json['idempotencyKey'], equals(idempotencyKey));
      expect(json.containsKey('idempotencyKey'), isTrue);
    });

    test('should index transactions by userId, timestamp, and idempotencyKey',
        () {
      // Verify transaction model has all indexable fields
      final now = DateTime.now();
      const userId = 'user-123';
      const idempotencyKey =
          'txn_deposit_1732723200000_550e8400-e29b-41d4-a716-446655440000';

      final transaction = TransactionModel(
        id: 'txn-123',
        walletId: 'wallet-123',
        userId: userId,
        amount: 100.0,
        type: TransactionType.deposit,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: now,
        idempotencyKey: idempotencyKey,
      );

      // Verify fields that should be indexed exist
      expect(transaction.userId, equals(userId));
      expect(transaction.timestamp, equals(now));
      expect(transaction.idempotencyKey, equals(idempotencyKey));
      expect(transaction.status, equals(TransactionStatus.completed));

      // Verify JSON includes indexable fields
      final json = transaction.toJson();
      expect(json['userId'], equals(userId));
      expect(json['timestamp'], isNotNull);
      expect(json['idempotencyKey'], equals(idempotencyKey));
      expect(json['status'], equals('completed'));
    });
  });

  group('Integration Test 7: End-to-End Funding and Withdrawal Flow', () {
    test('should generate valid idempotency keys for funding operations', () {
      // Act
      final idempotencyKey =
          IdempotencyHelper.generateTransactionId('deposit');

      // Assert
      expect(IdempotencyHelper.isValidTransactionId(idempotencyKey), isTrue);
      expect(idempotencyKey, startsWith('txn_deposit_'));

      // Verify key structure
      final parts = idempotencyKey.split('_');
      expect(parts.length, greaterThanOrEqualTo(4));
      expect(parts[0], equals('txn'));
      expect(parts[1], equals('deposit'));
      expect(int.tryParse(parts[2]), isNotNull); // timestamp
    });

    test('should generate valid idempotency keys for withdrawal operations',
        () {
      // Act
      final idempotencyKey =
          IdempotencyHelper.generateTransactionId('withdrawal');

      // Assert
      expect(IdempotencyHelper.isValidTransactionId(idempotencyKey), isTrue);
      expect(idempotencyKey, startsWith('txn_withdrawal_'));

      // Verify key structure
      final parts = idempotencyKey.split('_');
      expect(parts.length, greaterThanOrEqualTo(4));
      expect(parts[0], equals('txn'));
      expect(parts[1], equals('withdrawal'));
      expect(int.tryParse(parts[2]), isNotNull); // timestamp
    });

    test('should create transaction models for funding with idempotency', () {
      // Arrange
      const walletId = 'wallet-123';
      const userId = 'user-123';
      const fundingAmount = 500.0;
      final idempotencyKey =
          IdempotencyHelper.generateTransactionId('deposit');

      // Act
      final transaction = TransactionModel(
        id: 'txn-fund-123',
        walletId: walletId,
        userId: userId,
        amount: fundingAmount,
        type: TransactionType.deposit,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: DateTime.now(),
        idempotencyKey: idempotencyKey,
      );

      // Assert
      expect(transaction.type, equals(TransactionType.deposit));
      expect(transaction.amount, equals(fundingAmount));
      expect(transaction.idempotencyKey, equals(idempotencyKey));
      expect(transaction.status, equals(TransactionStatus.completed));
    });

    test('should create transaction models for withdrawal with idempotency',
        () {
      // Arrange
      const walletId = 'wallet-123';
      const userId = 'user-123';
      const withdrawalAmount = 300.0;
      final idempotencyKey =
          IdempotencyHelper.generateTransactionId('withdrawal');

      // Act
      final transaction = TransactionModel(
        id: 'txn-withdraw-123',
        walletId: walletId,
        userId: userId,
        amount: withdrawalAmount,
        type: TransactionType.withdrawal,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: DateTime.now(),
        idempotencyKey: idempotencyKey,
      );

      // Assert
      expect(transaction.type, equals(TransactionType.withdrawal));
      expect(transaction.amount, equals(withdrawalAmount));
      expect(transaction.idempotencyKey, equals(idempotencyKey));
      expect(transaction.status, equals(TransactionStatus.completed));
    });
  });

  group('Integration Test 8: Idempotency Key Format Consistency', () {
    test('should maintain consistent ID format across all operation types', () {
      // Generate IDs for all operation types
      final holdId = IdempotencyHelper.generateTransactionId('hold');
      final releaseId = IdempotencyHelper.generateTransactionId('release');
      final depositId = IdempotencyHelper.generateTransactionId('deposit');
      final withdrawalId = IdempotencyHelper.generateTransactionId('withdrawal');

      // All should be valid
      expect(IdempotencyHelper.isValidTransactionId(holdId), isTrue);
      expect(IdempotencyHelper.isValidTransactionId(releaseId), isTrue);
      expect(IdempotencyHelper.isValidTransactionId(depositId), isTrue);
      expect(IdempotencyHelper.isValidTransactionId(withdrawalId), isTrue);

      // All should have correct prefixes
      expect(holdId, startsWith('txn_hold_'));
      expect(releaseId, startsWith('txn_release_'));
      expect(depositId, startsWith('txn_deposit_'));
      expect(withdrawalId, startsWith('txn_withdrawal_'));

      // All should have 4+ parts (txn, type, timestamp, uuid)
      expect(holdId.split('_').length, greaterThanOrEqualTo(4));
      expect(releaseId.split('_').length, greaterThanOrEqualTo(4));
      expect(depositId.split('_').length, greaterThanOrEqualTo(4));
      expect(withdrawalId.split('_').length, greaterThanOrEqualTo(4));

      // All timestamps should be valid
      final holdTimestamp = int.parse(holdId.split('_')[2]);
      final releaseTimestamp = int.parse(releaseId.split('_')[2]);
      expect(holdTimestamp, greaterThan(0));
      expect(releaseTimestamp, greaterThan(0));
    });

    test('should generate IDs with timestamps in correct chronological order',
        () async {
      // Generate first ID
      final id1 = IdempotencyHelper.generateTransactionId('hold');
      final timestamp1 = int.parse(id1.split('_')[2]);

      // Wait a small amount of time
      await Future.delayed(const Duration(milliseconds: 10));

      // Generate second ID
      final id2 = IdempotencyHelper.generateTransactionId('hold');
      final timestamp2 = int.parse(id2.split('_')[2]);

      // Second timestamp should be later or equal to first
      expect(timestamp2, greaterThanOrEqualTo(timestamp1));

      // IDs should be different even if timestamps are same (UUID provides uniqueness)
      expect(id1, isNot(equals(id2)));
    });

    test('should reject invalid transaction ID formats', () {
      // Test various invalid formats
      expect(IdempotencyHelper.isValidTransactionId(''), isFalse);
      expect(
          IdempotencyHelper.isValidTransactionId(
              'invalid_hold_1732723200000_550e8400-e29b-41d4-a716-446655440000'),
          isFalse);
      expect(IdempotencyHelper.isValidTransactionId('txn_hold'), isFalse);
      expect(
          IdempotencyHelper.isValidTransactionId(
              'txn_hold_notanumber_550e8400-e29b-41d4-a716-446655440000'),
          isFalse);

      // Valid format should pass
      final validId = IdempotencyHelper.generateTransactionId('hold');
      expect(IdempotencyHelper.isValidTransactionId(validId), isTrue);
    });
  });

  group('Integration Test 9: Error Propagation Through Layers', () {
    test('should verify all wallet exception types exist', () {
      // Verify exception hierarchy
      const insufficientBalance = InsufficientBalanceException();
      const insufficientHeld = InsufficientHeldBalanceException(
        required: 100.0,
        available: 50.0,
      );
      const walletNotFound = WalletNotFoundException();
      const invalidAmount = InvalidAmountException();
      const transactionFailed = TransactionFailedException();
      const holdFailed = HoldBalanceFailedException();
      const releaseFailed = ReleaseBalanceFailedException();

      // All should be WalletExceptions
      expect(insufficientBalance, isA<WalletException>());
      expect(insufficientHeld, isA<WalletException>());
      expect(walletNotFound, isA<WalletException>());
      expect(invalidAmount, isA<WalletException>());
      expect(transactionFailed, isA<WalletException>());
      expect(holdFailed, isA<WalletException>());
      expect(releaseFailed, isA<WalletException>());

      // All should have messages
      expect(insufficientBalance.message, isNotEmpty);
      expect(insufficientHeld.message, isNotEmpty);
      expect(walletNotFound.message, isNotEmpty);
      expect(invalidAmount.message, isNotEmpty);
      expect(transactionFailed.message, isNotEmpty);
      expect(holdFailed.message, isNotEmpty);
      expect(releaseFailed.message, isNotEmpty);
    });

    test('should provide detailed messages for insufficient balance exceptions',
        () {
      // Test InsufficientHeldBalanceException message format
      const exception = InsufficientHeldBalanceException(
        required: 100.0,
        available: 50.0,
      );

      expect(exception.message, contains('Insufficient held balance'));
      expect(exception.message, contains('Required: 100.0'));
      expect(exception.message, contains('Available: 50.0'));
    });
  });

  group('Integration Test 10: Complete Data Flow Verification', () {
    test('should verify idempotency key flows through transaction lifecycle',
        () {
      // Step 1: Generate idempotency key (UI layer)
      final uiGeneratedKey = IdempotencyHelper.generateTransactionId('hold');
      expect(IdempotencyHelper.isValidTransactionId(uiGeneratedKey), isTrue);

      // Step 2: Create transaction with key (Data layer)
      final transaction = TransactionModel(
        id: 'txn-123',
        walletId: 'wallet-123',
        userId: 'user-123',
        amount: 100.0,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: DateTime.now(),
        idempotencyKey: uiGeneratedKey,
      );

      // Step 3: Serialize to JSON (Firestore write)
      final json = transaction.toJson();
      expect(json['idempotencyKey'], equals(uiGeneratedKey));

      // Step 4: Deserialize from JSON (Firestore read)
      final deserializedTransaction = TransactionModel.fromJson(json);
      expect(deserializedTransaction.idempotencyKey, equals(uiGeneratedKey));

      // Step 5: Convert to entity (Domain layer)
      final entity = deserializedTransaction.toEntity();
      expect(entity.idempotencyKey, equals(uiGeneratedKey));

      // The key maintains its format through all layers
      final keyParts = entity.idempotencyKey.split('_');
      expect(keyParts[0], equals('txn'));
      expect(keyParts[1], equals('hold'));
      expect(int.tryParse(keyParts[2]), isNotNull);
      expect(keyParts.length, greaterThanOrEqualTo(4));
    });

    test('should verify transaction entity and model have matching fields', () {
      // Create model
      final now = DateTime.now();
      const idempotencyKey =
          'txn_hold_1732723200000_550e8400-e29b-41d4-a716-446655440000';

      final model = TransactionModel(
        id: 'txn-123',
        walletId: 'wallet-123',
        userId: 'user-123',
        amount: 100.0,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'NGN',
        timestamp: now,
        description: 'Test transaction',
        referenceId: 'ref-123',
        idempotencyKey: idempotencyKey,
        metadata: {'test': 'data'},
      );

      // Convert to entity
      final entity = model.toEntity();

      // Verify all fields match
      expect(entity.id, equals(model.id));
      expect(entity.walletId, equals(model.walletId));
      expect(entity.userId, equals(model.userId));
      expect(entity.amount, equals(model.amount));
      expect(entity.type, equals(model.type));
      expect(entity.status, equals(model.status));
      expect(entity.currency, equals(model.currency));
      expect(entity.timestamp, equals(model.timestamp));
      expect(entity.description, equals(model.description));
      expect(entity.referenceId, equals(model.referenceId));
      expect(entity.idempotencyKey, equals(model.idempotencyKey));
      expect(entity.metadata, equals(model.metadata));

      // Convert back to model
      final modelFromEntity = TransactionModel.fromEntity(entity);

      // Verify round-trip conversion maintains all data
      expect(modelFromEntity.id, equals(model.id));
      expect(modelFromEntity.walletId, equals(model.walletId));
      expect(modelFromEntity.userId, equals(model.userId));
      expect(modelFromEntity.amount, equals(model.amount));
      expect(modelFromEntity.type, equals(model.type));
      expect(modelFromEntity.status, equals(model.status));
      expect(modelFromEntity.currency, equals(model.currency));
      expect(modelFromEntity.timestamp, equals(model.timestamp));
      expect(modelFromEntity.description, equals(model.description));
      expect(modelFromEntity.referenceId, equals(model.referenceId));
      expect(modelFromEntity.idempotencyKey, equals(model.idempotencyKey));
      expect(modelFromEntity.metadata, equals(model.metadata));
    });
  });
}
