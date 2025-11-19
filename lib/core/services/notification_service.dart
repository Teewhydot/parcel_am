import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../routes/routes.dart';
import 'navigation_service/nav_config.dart';
import '../domain/repositories/notification_repository.dart';

/// Top-level background message handler
/// Must be a top-level function for Firebase Messaging background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.messageId}');
  }

  // Display notification from background handler
  await _showBackgroundNotification(message);
}

/// Helper function to display notification from background
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  final notification = message.notification;
  final data = message.data;

  final title = notification?.title ?? data['title'] as String? ?? '';
  final body = notification?.body ?? data['body'] as String? ?? '';
  final chatId = data['chatId'] as String?;

  const androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    channelDescription: 'Notifications for new chat messages',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  final payload = jsonEncode({
    'chatId': chatId,
    'messageId': message.messageId,
  });

  await localNotifications.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

/// Notification Service Singleton
/// Manages FCM and local notifications
class NotificationService {
  static NotificationService? _instance;

  final NotificationRepository repository;
  final FlutterLocalNotificationsPlugin localNotifications;
  final NotificationRemoteDataSource remoteDataSource;
  final NavigationService navigationService;
  final FirebaseAuth firebaseAuth;

  bool _isInitialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  NotificationService({
    required this.repository,
    required this.localNotifications,
    required this.remoteDataSource,
    required this.navigationService,
    required this.firebaseAuth,
  });

  /// Get singleton instance
  factory NotificationService.getInstance({
    required NotificationRepository repository,
    required FlutterLocalNotificationsPlugin localNotifications,
    required NotificationRemoteDataSource remoteDataSource,
    required NavigationService navigationService,
    required FirebaseAuth firebaseAuth,
  }) {
    _instance ??= NotificationService(
      repository: repository,
      localNotifications: localNotifications,
      remoteDataSource: remoteDataSource,
      navigationService: navigationService,
      firebaseAuth: firebaseAuth,
    );
    return _instance!;
  }

  bool get isInitialized => _isInitialized;
  String? get currentToken => _currentToken;

  /// Initialize notification service
  /// Called from main.dart after Firebase initialization, before runApp
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('NotificationService already initialized');
      }
      return;
    }

    try {
      // Request notification permissions for iOS/web
      if (Platform.isIOS || kIsWeb) {
        await requestPermissions();
      }

      // Initialize flutter_local_notifications with platform-specific settings
      await _initializeLocalNotifications();

      // Configure Android notification channels
      await _configureAndroidChannels();

      // Configure iOS/Darwin notification settings
      await _configureIOSSettings();

      // Get and store FCM token
      final token = await getToken();
      if (token != null) {
        await storeToken(token);
      }

      // Subscribe to token refresh
      _tokenRefreshSubscription = repository.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        storeToken(newToken);
      });

      // Subscribe to foreground messages
      _foregroundMessageSubscription =
          repository.onForegroundMessage.listen(handleForegroundMessage);

      _isInitialized = true;

      if (kDebugMode) {
        print('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
      rethrow;
    }
  }

  /// Initialize local notifications with platform-specific settings
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: handleNotificationTap,
    );
  }

  /// Configure Android notification channels
  Future<void> _configureAndroidChannels() async {
    if (!Platform.isAndroid) return;

    const androidChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Configure iOS/Darwin notification settings
  Future<void> _configureIOSSettings() async {
    if (!Platform.isIOS) return;

    await localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      _currentToken = await repository.getFCMToken();
      if (kDebugMode) {
        print('FCM Token: $_currentToken');
      }
      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Store FCM token to Firestore users/{userId}/fcmTokens array
  Future<void> storeToken(String token) async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null) {
        if (kDebugMode) {
          print('Cannot store token: No user logged in');
        }
        return;
      }

      await repository.storeFCMToken(userId, token);

      if (kDebugMode) {
        print('FCM token stored for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing FCM token: $e');
      }
    }
  }

  /// Handle foreground messages
  /// Subscribe to FirebaseMessaging.onMessage stream
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('Foreground message received: ${message.messageId}');
      }

      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      // Extract notification data
      final notification = message.notification;
      final data = message.data;

      final title = notification?.title ?? data['title'] as String? ?? '';
      final body = notification?.body ?? data['body'] as String? ?? '';
      final chatId = data['chatId'] as String?;

      // Display local notification
      await _displayLocalNotification(
        message: message,
        title: title,
        body: body,
        chatId: chatId,
      );

      // Save notification to Firestore
      final notificationModel = NotificationModel.fromRemoteMessage(
        message,
        userId,
      );
      await remoteDataSource.saveNotification(notificationModel);

      // Update badge count
      await _updateBadgeCount();

      if (kDebugMode) {
        print('Foreground notification processed and saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling foreground message: $e');
      }
    }
  }

  /// Display local notification using flutter_local_notifications
  Future<void> _displayLocalNotification({
    required RemoteMessage message,
    required String title,
    required String body,
    String? chatId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      groupKey: 'chat_group',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload with chatId for navigation
    final payload = jsonEncode({
      'chatId': chatId,
      'messageId': message.messageId,
      'notificationId': message.messageId,
    });

    await localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle background messages
  /// This is called by the background handler
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('Background message handler: ${message.messageId}');
      }

      // Extract chat details from data payload
      final data = message.data;
      final notification = message.notification;

      final senderName = data['senderName'] as String? ?? 'Someone';
      final messageContent = notification?.body ?? data['body'] as String? ?? '';
      final chatId = data['chatId'] as String?;

      // Display local notification from background handler
      const androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({
        'chatId': chatId,
        'messageId': message.messageId,
      });

      await localNotifications.show(
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        senderName,
        messageContent,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        print('Background notification displayed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling background message: $e');
      }
    }
  }

  /// Handle notification tap
  /// Parse notification payload JSON and navigate to ChatScreen
  Future<void> handleNotificationTap(NotificationResponse response) async {
    try {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) {
        if (kDebugMode) {
          print('Notification tapped with no payload');
        }
        return;
      }

      // Parse payload JSON
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final chatId = data['chatId'] as String?;
      final notificationId = data['notificationId'] as String?;

      if (kDebugMode) {
        print('Notification tapped - chatId: $chatId, notificationId: $notificationId');
      }

      // Mark notification as read if notificationId exists
      if (notificationId != null) {
        await remoteDataSource.markAsRead(notificationId);
        // Update badge count after marking as read
        await _updateBadgeCount();
      }

      // Navigate to ChatScreen with chatId parameter
      if (chatId != null) {
        await navigationService.navigateTo(
          Routes.chat,
          arguments: {'chatId': chatId},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification tap: $e');
      }
    }
  }

  /// Request notification permissions
  Future<AuthorizationStatus> requestPermissions() async {
    try {
      final status = await repository.requestPermissions();

      if (kDebugMode) {
        print('Notification permission status: $status');
      }

      return status;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
      return AuthorizationStatus.denied;
    }
  }

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await repository.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await repository.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// Calculate total unread notification count from Firestore
  Future<int> _getTotalUnreadCount() async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null) return 0;

      return await repository.getUnreadNotificationCount(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Update app badge count based on total unread notifications
  Future<void> _updateBadgeCount() async {
    try {
      final unreadCount = await _getTotalUnreadCount();
      await updateBadgeCount(unreadCount);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating badge count: $e');
      }
    }
  }

  /// Update app badge count
  /// This method can also be called publicly to manually update badge
  Future<void> updateBadgeCount(int count) async {
    try {
      // Check if the device supports app badges
      final isSupported = await AppBadgePlus.isSupported();

      if (isSupported) {
        await AppBadgePlus.updateBadge(count);

        if (kDebugMode) {
          print('Badge count updated to: $count');
        }
      } else {
        if (kDebugMode) {
          print('App badges not supported on this device');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating badge count: $e');
      }
    }
  }

  /// Clear app badge (set to 0)
  Future<void> clearBadge() async {
    try {
      await AppBadgePlus.updateBadge(0);
      if (kDebugMode) {
        print('Badge cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing badge: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
  }
}
