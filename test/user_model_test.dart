import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/travellink/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel without phoneNumber field', () {
      final userModel = UserModel(
        uid: 'test-uid',
        displayName: 'Test User',
        email: 'test@example.com',
        isVerified: true,
        verificationStatus: 'verified',
        createdAt: DateTime.now(),
        additionalData: {},
      );

      expect(userModel.uid, 'test-uid');
      expect(userModel.displayName, 'Test User');
      expect(userModel.email, 'test@example.com');
      expect(userModel.isVerified, true);
      expect(userModel.verificationStatus, 'verified');
    });

    test('should convert to JSON without phoneNumber field', () {
      final userModel = UserModel(
        uid: 'test-uid',
        displayName: 'Test User',
        email: 'test@example.com',
        isVerified: true,
        verificationStatus: 'verified',
        createdAt: DateTime(2024, 1, 1),
        additionalData: {},
      );

      final json = userModel.toJson();

      expect(json['uid'], 'test-uid');
      expect(json['displayName'], 'Test User');
      expect(json['email'], 'test@example.com');
      expect(json['isVerified'], true);
      expect(json['verificationStatus'], 'verified');
      expect(json.containsKey('phoneNumber'), false);
    });

    test('should create from JSON without phoneNumber field', () {
      final json = {
        'uid': 'test-uid',
        'displayName': 'Test User',
        'email': 'test@example.com',
        'isVerified': true,
        'verificationStatus': 'verified',
        'createdAt': '2024-01-01T00:00:00.000',
        'additionalData': {},
      };

      final userModel = UserModel.fromJson(json);

      expect(userModel.uid, 'test-uid');
      expect(userModel.displayName, 'Test User');
      expect(userModel.email, 'test@example.com');
      expect(userModel.isVerified, true);
      expect(userModel.verificationStatus, 'verified');
    });

    test('should copy with new values', () {
      final userModel = UserModel(
        uid: 'test-uid',
        displayName: 'Test User',
        email: 'test@example.com',
        isVerified: false,
        verificationStatus: 'pending',
        createdAt: DateTime.now(),
        additionalData: {},
      );

      final updatedModel = userModel.copyWith(
        displayName: 'Updated User',
        email: 'updated@example.com',
        isVerified: true,
        verificationStatus: 'verified',
      );

      expect(updatedModel.uid, 'test-uid');
      expect(updatedModel.displayName, 'Updated User');
      expect(updatedModel.email, 'updated@example.com');
      expect(updatedModel.isVerified, true);
      expect(updatedModel.verificationStatus, 'verified');
    });
  });
}
