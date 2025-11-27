import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/parcel_am_core/data/helpers/idempotency_helper.dart';

void main() {
  group('IdempotencyHelper', () {
    group('generateTransactionId', () {
      test('should generate ID with correct format txn_{type}_{timestamp}_{uuid}', () {
        // Arrange
        final operationType = 'hold';

        // Act
        final id = IdempotencyHelper.generateTransactionId(operationType);

        // Assert
        expect(id.startsWith('txn_${operationType}_'), isTrue);
        expect(id.split('_').length, greaterThanOrEqualTo(4));
      });

      test('should generate unique IDs for multiple calls', () {
        // Act
        final id1 = IdempotencyHelper.generateTransactionId('deposit');
        final id2 = IdempotencyHelper.generateTransactionId('deposit');

        // Assert
        expect(id1, isNot(equals(id2)));
      });

      test('should include timestamp in generated ID', () {
        // Arrange
        final beforeTimestamp = DateTime.now().millisecondsSinceEpoch;

        // Act
        final id = IdempotencyHelper.generateTransactionId('release');

        // Assert
        final parts = id.split('_');
        final timestamp = int.parse(parts[2]);
        expect(timestamp, greaterThanOrEqualTo(beforeTimestamp));
      });
    });

    group('isValidTransactionId', () {
      test('should return true for valid transaction ID', () {
        // Arrange
        final validId = IdempotencyHelper.generateTransactionId('hold');

        // Act
        final result = IdempotencyHelper.isValidTransactionId(validId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for empty string', () {
        // Act
        final result = IdempotencyHelper.isValidTransactionId('');

        // Assert
        expect(result, isFalse);
      });

      test('should return false for ID not starting with txn', () {
        // Arrange
        final invalidId = 'invalid_hold_1732723200000_550e8400-e29b-41d4-a716-446655440000';

        // Act
        final result = IdempotencyHelper.isValidTransactionId(invalidId);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for ID with invalid timestamp', () {
        // Arrange
        final invalidId = 'txn_hold_notanumber_550e8400-e29b-41d4-a716-446655440000';

        // Act
        final result = IdempotencyHelper.isValidTransactionId(invalidId);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for ID with too few parts', () {
        // Arrange
        final invalidId = 'txn_hold';

        // Act
        final result = IdempotencyHelper.isValidTransactionId(invalidId);

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
