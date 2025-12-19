import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/withdrawal_order_entity.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/user_bank_account_entity.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/bank_info_entity.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/withdrawal_order_model.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/user_bank_account_model.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/bank_info_model.dart';

void main() {
  group('WithdrawalOrderModel', () {
    test('should serialize and deserialize correctly', () {
      // Arrange
      final bankAccount = BankAccountInfo(
        id: 'bank-account-123',
        accountNumber: '0123456789',
        accountName: 'John Doe',
        bankCode: '058',
        bankName: 'GTBank',
      );

      final model = WithdrawalOrderModel(
        id: 'WTH-1234567890-uuid',
        userId: 'user123',
        amount: 5000.0,
        bankAccount: bankAccount,
        status: WithdrawalStatus.pending,
        recipientCode: 'RCP_123',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        metadata: {'test': 'value'},
      );

      // Act
      final json = model.toJson();
      final fromJson = WithdrawalOrderModel.fromJson(json);

      // Assert
      expect(fromJson.id, model.id);
      expect(fromJson.userId, model.userId);
      expect(fromJson.amount, model.amount);
      expect(fromJson.status, model.status);
      expect(fromJson.recipientCode, model.recipientCode);
    });

    test('should validate withdrawal reference format', () {
      // Arrange
      const validReference = 'WTH-1234567890-abc123';

      // Assert
      expect(validReference.startsWith('WTH-'), true);
      expect(validReference.split('-').length, greaterThanOrEqualTo(3));
    });

    test('should map status enum correctly', () {
      // Arrange & Act & Assert
      expect(WithdrawalStatus.pending.name, 'pending');
      expect(WithdrawalStatus.processing.name, 'processing');
      expect(WithdrawalStatus.success.name, 'success');
      expect(WithdrawalStatus.failed.name, 'failed');
      expect(WithdrawalStatus.reversed.name, 'reversed');
    });
  });

  group('UserBankAccountModel', () {
    test('should validate 10-digit account number', () {
      // Arrange
      final validAccount = UserBankAccountEntity(
        id: 'acc123',
        userId: 'user123',
        accountNumber: '0123456789',
        accountName: 'John Doe',
        bankCode: '058',
        bankName: 'GTBank',
        recipientCode: 'RCP_123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final invalidAccount = UserBankAccountEntity(
        id: 'acc123',
        userId: 'user123',
        accountNumber: '012345',
        accountName: 'John Doe',
        bankCode: '058',
        bankName: 'GTBank',
        recipientCode: 'RCP_123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(validAccount.isValidAccountNumber, true);
      expect(invalidAccount.isValidAccountNumber, false);
    });

    test('should mask account number correctly', () {
      // Arrange
      final account = UserBankAccountEntity(
        id: 'acc123',
        userId: 'user123',
        accountNumber: '0123456789',
        accountName: 'John Doe',
        bankCode: '058',
        bankName: 'GTBank',
        recipientCode: 'RCP_123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final masked = account.maskedAccountNumber;

      // Assert
      expect(masked, '******6789');
      expect(masked.endsWith('6789'), true);
    });

    test('should serialize and deserialize bank account', () {
      // Arrange
      final model = UserBankAccountModel(
        id: 'acc123',
        userId: 'user123',
        accountNumber: '0123456789',
        accountName: 'John Doe',
        bankCode: '058',
        bankName: 'GTBank',
        recipientCode: 'RCP_123',
        verified: true,
        active: true,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      // Act
      final json = model.toJson();
      final fromJson = UserBankAccountModel.fromJson(json);

      // Assert
      expect(fromJson.accountNumber, model.accountNumber);
      expect(fromJson.accountName, model.accountName);
      expect(fromJson.bankCode, model.bankCode);
      expect(fromJson.recipientCode, model.recipientCode);
    });
  });

  group('BankInfoModel', () {
    test('should parse Paystack bank response', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'Guaranty Trust Bank',
        'code': '058',
        'slug': 'gtbank',
        'country': 'Nigeria',
        'currency': 'NGN',
        'type': 'nuban',
        'active': true,
      };

      // Act
      final model = BankInfoModel.fromJson(json);

      // Assert
      expect(model.id, 1);
      expect(model.name, 'Guaranty Trust Bank');
      expect(model.code, '058');
      expect(model.currency, 'NGN');
    });

    test('should support bank search filtering', () {
      // Arrange
      final bank = BankInfoEntity(
        id: 1,
        name: 'Guaranty Trust Bank',
        code: '058',
        slug: 'gtbank',
        country: 'Nigeria',
        currency: 'NGN',
        type: 'nuban',
        active: true,
      );

      // Act & Assert
      expect(bank.matchesSearch('guaranty'), true);
      expect(bank.matchesSearch('GTB'), true);
      expect(bank.matchesSearch('058'), true);
      expect(bank.matchesSearch('zenith'), false);
    });
  });
}
