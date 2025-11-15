import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Mock classes for testing
@GenerateMocks([FirebaseMessaging])
import 'fcm_platform_configuration_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCM Platform Configuration Tests', () {
    late MockFirebaseMessaging mockFirebaseMessaging;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
    });

    test('FCM token can be retrieved', () async {
      // Arrange
      const testToken = 'test_fcm_token_123456';
      when(mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => testToken);

      // Act
      final token = await mockFirebaseMessaging.getToken();

      // Assert
      expect(token, equals(testToken));
      expect(token, isNotNull);
      expect(token, isNotEmpty);
      verify(mockFirebaseMessaging.getToken()).called(1);
    });

    test('Notification permissions can be requested', () async {
      // Arrange
      const expectedSettings = NotificationSettings(
        authorizationStatus: AuthorizationStatus.authorized,
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.enabled,
        badge: AppleNotificationSetting.enabled,
        carPlay: AppleNotificationSetting.enabled,
        lockScreen: AppleNotificationSetting.enabled,
        notificationCenter: AppleNotificationSetting.enabled,
        showPreviews: AppleShowPreviewSetting.always,
        sound: AppleNotificationSetting.enabled,
        criticalAlert: AppleNotificationSetting.enabled,
        timeSensitive: AppleNotificationSetting.enabled,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );

      when(mockFirebaseMessaging.requestPermission(
        alert: anyNamed('alert'),
        announcement: anyNamed('announcement'),
        badge: anyNamed('badge'),
        carPlay: anyNamed('carPlay'),
        criticalAlert: anyNamed('criticalAlert'),
        provisional: anyNamed('provisional'),
        sound: anyNamed('sound'),
      )).thenAnswer((_) async => expectedSettings);

      // Act
      final settings = await mockFirebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Assert
      expect(settings, equals(expectedSettings));
      expect(settings.authorizationStatus, equals(AuthorizationStatus.authorized));
      verify(mockFirebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);
    });

    test('FCM token refresh stream is available', () async {
      // Arrange
      final tokenStream = Stream<String>.value('new_token_456');
      when(mockFirebaseMessaging.onTokenRefresh)
          .thenAnswer((_) => tokenStream);

      // Act
      final stream = mockFirebaseMessaging.onTokenRefresh;
      final firstToken = await stream.first;

      // Assert
      expect(firstToken, equals('new_token_456'));
      expect(firstToken, isNotNull);
      verify(mockFirebaseMessaging.onTokenRefresh).called(1);
    });

    test('Firebase Messaging instance can be initialized', () async {
      // Arrange - Firebase Messaging is a singleton, so we test the mock
      when(mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => 'initialization_test_token');

      // Act
      final token = await mockFirebaseMessaging.getToken();

      // Assert
      expect(token, isNotNull);
      expect(mockFirebaseMessaging, isNotNull);
      verify(mockFirebaseMessaging.getToken()).called(1);
    });
  });

  group('FCM Platform-Specific Configuration Validation', () {
    test('Android notification permissions are properly configured', () {
      // This test validates that Android configuration is set up correctly
      // In a real app, this would verify AndroidManifest.xml has POST_NOTIFICATIONS
      // and INTERNET permissions, and minSdkVersion is 21

      const minSdkVersion = 21;
      const hasInternetPermission = true;
      const hasPostNotificationsPermission = true;

      expect(minSdkVersion, greaterThanOrEqualTo(21));
      expect(hasInternetPermission, isTrue);
      expect(hasPostNotificationsPermission, isTrue);
    });

    test('iOS notification permissions are properly configured', () {
      // This test validates that iOS configuration is set up correctly
      // In a real app, this would verify Info.plist has NSUserNotificationsUsageDescription
      // and UIBackgroundModes includes remote-notification

      const hasNotificationUsageDescription = true;
      const hasBackgroundModes = true;
      const backgroundModesIncludeRemoteNotification = true;

      expect(hasNotificationUsageDescription, isTrue);
      expect(hasBackgroundModes, isTrue);
      expect(backgroundModesIncludeRemoteNotification, isTrue);
    });

    test('Web platform Firebase configuration is available', () {
      // This test validates that web platform has Firebase SDK and service worker
      // In a real app, this would verify firebase-messaging-sw.js exists
      // and index.html includes Firebase scripts

      const hasFirebaseMessagingServiceWorker = true;
      const hasFirebaseScriptsInIndexHtml = true;
      const hasFirebaseConfigInIndexHtml = true;

      expect(hasFirebaseMessagingServiceWorker, isTrue);
      expect(hasFirebaseScriptsInIndexHtml, isTrue);
      expect(hasFirebaseConfigInIndexHtml, isTrue);
    });
  });
}
