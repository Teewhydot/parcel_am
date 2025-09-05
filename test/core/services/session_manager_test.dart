import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:parcel_am/core/services/session/session_manager.dart';
import 'package:parcel_am/core/services/firebase/firebase_service.dart';

import 'session_manager_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage, FirebaseService, FirebaseAuth, User])
void main() {
  late SessionManager sessionManager;
  late MockFlutterSecureStorage mockStorage;
  late MockFirebaseService mockFirebaseService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockFirebaseService = MockFirebaseService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Mock FirebaseService singleton
    when(FirebaseService.instance).thenReturn(mockFirebaseService);
    when(mockFirebaseService.auth).thenReturn(mockAuth);

    sessionManager = SessionManager.instance;
  });

  group('SessionManager', () {
    group('saveSession', () {
      test('saves user session data to secure storage', () async {
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.phoneNumber).thenReturn('+2348012345678');
        when(mockUser.displayName).thenReturn('Test User');

        await sessionManager.saveSession(mockUser);

        verify(mockStorage.write(key: 'is_logged_in', value: 'true')).called(1);
        verify(mockStorage.write(key: 'user_id', value: 'test-uid')).called(1);
        verify(mockStorage.write(key: 'user_phone', value: '+2348012345678')).called(1);
        verify(mockStorage.write(key: 'user_display_name', value: 'Test User')).called(1);
      });

      test('handles storage errors gracefully', () async {
        when(mockUser.uid).thenReturn('test-uid');
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenThrow(Exception('Storage error'));

        // Should not throw exception
        await expectLater(
          sessionManager.saveSession(mockUser),
          completes,
        );
      });

      test('handles null values in user data', () async {
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.phoneNumber).thenReturn(null);
        when(mockUser.displayName).thenReturn(null);

        await sessionManager.saveSession(mockUser);

        verify(mockStorage.write(key: 'user_phone', value: '')).called(1);
        verify(mockStorage.write(key: 'user_display_name', value: '')).called(1);
      });
    });

    group('clearSession', () {
      test('deletes all session data', () async {
        await sessionManager.clearSession();

        verify(mockStorage.deleteAll()).called(1);
      });

      test('handles storage errors gracefully', () async {
        when(mockStorage.deleteAll()).thenThrow(Exception('Storage error'));

        // Should not throw exception
        await expectLater(
          sessionManager.clearSession(),
          completes,
        );
      });
    });

    group('hasValidSession', () {
      test('returns true when logged in flag is true and Firebase user exists', () async {
        when(mockStorage.read(key: 'is_logged_in')).thenAnswer((_) async => 'true');
        when(mockAuth.currentUser).thenReturn(mockUser);

        final result = await sessionManager.hasValidSession();

        expect(result, isTrue);
      });

      test('returns false when logged in flag is false', () async {
        when(mockStorage.read(key: 'is_logged_in')).thenAnswer((_) async => 'false');
        when(mockAuth.currentUser).thenReturn(mockUser);

        final result = await sessionManager.hasValidSession();

        expect(result, isFalse);
      });

      test('returns false when Firebase user is null', () async {
        when(mockStorage.read(key: 'is_logged_in')).thenAnswer((_) async => 'true');
        when(mockAuth.currentUser).thenReturn(null);

        final result = await sessionManager.hasValidSession();

        expect(result, isFalse);
      });

      test('returns false when storage read fails', () async {
        when(mockStorage.read(key: 'is_logged_in')).thenThrow(Exception('Storage error'));

        final result = await sessionManager.hasValidSession();

        expect(result, isFalse);
      });
    });

    group('getStoredUserData', () {
      test('returns stored user data', () async {
        when(mockStorage.read(key: 'user_id')).thenAnswer((_) async => 'test-uid');
        when(mockStorage.read(key: 'user_phone')).thenAnswer((_) async => '+2348012345678');
        when(mockStorage.read(key: 'user_display_name')).thenAnswer((_) async => 'Test User');

        final result = await sessionManager.getStoredUserData();

        expect(result['uid'], equals('test-uid'));
        expect(result['phoneNumber'], equals('+2348012345678'));
        expect(result['displayName'], equals('Test User'));
      });

      test('handles storage read errors', () async {
        when(mockStorage.read(key: anyNamed('key'))).thenThrow(Exception('Storage error'));

        final result = await sessionManager.getStoredUserData();

        expect(result, isEmpty);
      });
    });

    group('updateDisplayName', () {
      test('updates display name in storage', () async {
        const newDisplayName = 'Updated User';

        await sessionManager.updateDisplayName(newDisplayName);

        verify(mockStorage.write(key: 'user_display_name', value: newDisplayName)).called(1);
      });

      test('handles storage write errors gracefully', () async {
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenThrow(Exception('Storage error'));

        // Should not throw exception
        await expectLater(
          sessionManager.updateDisplayName('New Name'),
          completes,
        );
      });
    });

    group('initializeSession', () {
      test('returns true when Firebase user exists and session is valid', () async {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockStorage.read(key: 'is_logged_in')).thenAnswer((_) async => 'true');
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.phoneNumber).thenReturn('+2348012345678');
        when(mockUser.displayName).thenReturn('Test User');

        final result = await sessionManager.initializeSession();

        expect(result, isTrue);
        verify(sessionManager.saveSession(mockUser)).called(1);
      });

      test('returns false when Firebase user is null', () async {
        when(mockAuth.currentUser).thenReturn(null);

        final result = await sessionManager.initializeSession();

        expect(result, isFalse);
        verify(mockStorage.deleteAll()).called(1);
      });

      test('returns false when session is invalid', () async {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockStorage.read(key: 'is_logged_in')).thenAnswer((_) async => 'false');

        final result = await sessionManager.initializeSession();

        expect(result, isFalse);
        verify(mockStorage.deleteAll()).called(1);
      });

      test('handles errors by clearing session', () async {
        when(mockAuth.currentUser).thenThrow(Exception('Firebase error'));

        final result = await sessionManager.initializeSession();

        expect(result, isFalse);
        verify(mockStorage.deleteAll()).called(1);
      });
    });

    group('isFirstTimeUser', () {
      test('returns true for first time users', () async {
        when(mockStorage.read(key: 'is_first_time')).thenAnswer((_) async => null);

        final result = await sessionManager.isFirstTimeUser();

        expect(result, isTrue);
        verify(mockStorage.write(key: 'is_first_time', value: 'false')).called(1);
      });

      test('returns false for returning users', () async {
        when(mockStorage.read(key: 'is_first_time')).thenAnswer((_) async => 'false');

        final result = await sessionManager.isFirstTimeUser();

        expect(result, isFalse);
      });

      test('returns true on storage errors', () async {
        when(mockStorage.read(key: 'is_first_time')).thenThrow(Exception('Storage error'));

        final result = await sessionManager.isFirstTimeUser();

        expect(result, isTrue);
      });
    });

    group('Singleton Pattern', () {
      test('returns same instance', () {
        final instance1 = SessionManager.instance;
        final instance2 = SessionManager.instance;

        expect(instance1, same(instance2));
      });
    });
  });
}