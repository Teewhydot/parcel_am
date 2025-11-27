import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/parcel_am_core/domain/helpers/wallet_validation_helper.dart';

void main() {
  group('WalletValidationHelper', () {
    group('validateAmountPositive', () {
      test('should return valid for positive amount', () {
        // Act
        final result = WalletValidationHelper.validateAmountPositive(100.0);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('should return invalid for zero amount', () {
        // Act
        final result = WalletValidationHelper.validateAmountPositive(0.0);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('greater than zero'));
      });

      test('should return invalid for negative amount', () {
        // Act
        final result = WalletValidationHelper.validateAmountPositive(-50.0);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('greater than zero'));
      });
    });

    group('validateSufficientBalance', () {
      test('should return valid when available balance is sufficient', () {
        // Act
        final result = WalletValidationHelper.validateSufficientBalance(
          required: 50.0,
          available: 100.0,
        );

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('should return invalid when available balance is insufficient', () {
        // Act
        final result = WalletValidationHelper.validateSufficientBalance(
          required: 150.0,
          available: 100.0,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Insufficient available balance'));
        expect(result.errorMessage, contains('Required: 150.0'));
        expect(result.errorMessage, contains('Available: 100.0'));
      });
    });

    group('validateSufficientHeldBalance', () {
      test('should return valid when held balance is sufficient', () {
        // Act
        final result = WalletValidationHelper.validateSufficientHeldBalance(
          required: 30.0,
          held: 50.0,
        );

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('should return invalid when held balance is insufficient', () {
        // Act
        final result = WalletValidationHelper.validateSufficientHeldBalance(
          required: 80.0,
          held: 50.0,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Insufficient pending balance'));
        expect(result.errorMessage, contains('Required: 80.0'));
        expect(result.errorMessage, contains('Available: 50.0'));
      });
    });
  });
}
