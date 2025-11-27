import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/transaction_model.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/transaction_entity.dart';

void main() {
  group('TransactionModel with idempotencyKey', () {
    const tIdempotencyKey = 'txn_hold_1732723200000_550e8400-e29b-41d4-a716-446655440000';
    final tTimestamp = DateTime(2024, 1, 1, 12, 0);

    test('should include idempotencyKey in toJson', () {
      // Arrange
      final model = TransactionModel(
        id: 'test_id',
        walletId: 'wallet_id',
        userId: 'user_id',
        amount: 100.0,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'USD',
        timestamp: tTimestamp,
        idempotencyKey: tIdempotencyKey,
      );

      // Act
      final json = model.toJson();

      // Assert
      expect(json['idempotencyKey'], equals(tIdempotencyKey));
    });

    test('should parse idempotencyKey from JSON', () {
      // Arrange
      final json = {
        'id': 'test_id',
        'walletId': 'wallet_id',
        'userId': 'user_id',
        'amount': 100.0,
        'type': 'hold',
        'status': 'completed',
        'currency': 'USD',
        'timestamp': tTimestamp.toIso8601String(),
        'idempotencyKey': tIdempotencyKey,
        'metadata': {},
      };

      // Act
      final model = TransactionModel.fromJson(json);

      // Assert
      expect(model.idempotencyKey, equals(tIdempotencyKey));
    });

    test('should convert to entity with idempotencyKey', () {
      // Arrange
      final model = TransactionModel(
        id: 'test_id',
        walletId: 'wallet_id',
        userId: 'user_id',
        amount: 100.0,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'USD',
        timestamp: tTimestamp,
        idempotencyKey: tIdempotencyKey,
      );

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity.idempotencyKey, equals(tIdempotencyKey));
      expect(entity, isA<TransactionEntity>());
    });

    test('should create from entity with idempotencyKey', () {
      // Arrange
      final entity = TransactionEntity(
        id: 'test_id',
        walletId: 'wallet_id',
        userId: 'user_id',
        amount: 100.0,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'USD',
        timestamp: tTimestamp,
        idempotencyKey: tIdempotencyKey,
      );

      // Act
      final model = TransactionModel.fromEntity(entity);

      // Assert
      expect(model.idempotencyKey, equals(tIdempotencyKey));
    });

    test('should include idempotencyKey in copyWith', () {
      // Arrange
      final model = TransactionModel(
        id: 'test_id',
        walletId: 'wallet_id',
        userId: 'user_id',
        amount: 100.0,
        type: TransactionType.hold,
        status: TransactionStatus.completed,
        currency: 'USD',
        timestamp: tTimestamp,
        idempotencyKey: tIdempotencyKey,
      );
      const newIdempotencyKey = 'txn_release_1732723300000_660e8400-e29b-41d4-a716-446655440000';

      // Act
      final copiedModel = model.copyWith(idempotencyKey: newIdempotencyKey);

      // Assert
      expect(copiedModel.idempotencyKey, equals(newIdempotencyKey));
      expect(copiedModel.id, equals(model.id));
    });
  });
}
