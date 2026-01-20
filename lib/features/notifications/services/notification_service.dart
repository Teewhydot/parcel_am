import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../domain/usecases/notification_usecase.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/models/notification_model.dart';
import '../../../core/routes/routes.dart';
import '../../../core/services/navigation_service/nav_config.dart';
import '../domain/repositories/fcm_repository.dart';

/// Top-level background message handler
/// Must be a top-level function for Firebase Messaging background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('[NotificationService] Background message received: ${message.messageId}');
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

  // Detect notification type from data payload
  final type = data['type'] as String?;
  final chatId = data['chatId'] as String?;
  final parcelId = data['parcelId'] as String?;
  final travelerId = data['travelerId'] as String?;
  final travelerName = data['travelerName'] as String?;

  // Use appropriate channel based on notification type
  final isParcelNotification = type == 'parcel_request_accepted' ||
      type == 'delivery_confirmation_required';

  final androidDetails = AndroidNotificationDetails(
    isParcelNotification ? 'parcel_updates' : 'chat_messages',
    isParcelNotification ? 'Parcel Updates' : 'Chat Messages',
    channelDescription: isParcelNotification
        ? 'Notifications for parcel request updates'
        : 'Notifications for new chat messages',
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

  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  // Create payload with appropriate fields
  final payload = jsonEncode({
    if (chatId != null) 'chatId': chatId,
    if (parcelId != null) 'parcelId': parcelId,
    if (travelerId != null) 'travelerId': travelerId,
    if (travelerName != null) 'travelerName': travelerName,
    if (type != null) 'type': type,
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

  final FCMRepository repository;
  final useCase = NotificationUseCase();
  final FlutterLocalNotificationsPlugin localNotifications;
  final NotificationRemoteDataSource remoteDataSource;
  final NavigationService navigationService;
  final FirebaseAuth firebaseAuth;

  bool _isInitialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  /// Currently viewed chat ID - used to suppress notifications for active chat
  String? _currentChatId;

  NotificationService({
    required this.repository,
    required this.localNotifications,
    required this.remoteDataSource,
    required this.navigationService,
    required this.firebaseAuth,
  });

  /// Get singleton instance
  factory NotificationService.getInstance({
    required FCMRepository repository,
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
  String? get currentChatId => _currentChatId;

  /// Set the current chat ID when user enters a chat screen
  /// Pass null when leaving the chat screen
  void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
    if (kDebugMode) {
      print('[NotificationService] Current chat ID set to: $chatId');
    }
  }

  /// Initialize notification service
  /// Called from main.dart after Firebase initialization, before runApp
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('[NotificationService] Already initialized');
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

      // Subscribe to token refresh first (this will capture the token when it becomes available)
      _tokenRefreshSubscription = repository.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        storeToken(newToken);
        if (kDebugMode) {
          print('[NotificationService] FCM token refreshed: $newToken');
        }
      });

      // Get and store FCM token (may be null on iOS initially if APNS token not ready)
      final token = await getToken();
      if (token != null) {
        await storeToken(token);
      } else {
        if (kDebugMode) {
          print('[NotificationService] FCM token not available during initialization. '
              'Will be retrieved when available via token refresh listener.');
        }
      }

      // Subscribe to foreground messages
      _foregroundMessageSubscription =
          repository.onForegroundMessage.listen(handleForegroundMessage);

      _isInitialized = true;

      if (kDebugMode) {
        print('[NotificationService] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error initializing: $e');
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

    // Chat messages channel
    const chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Parcel updates channel
    const parcelChannel = AndroidNotificationChannel(
      'parcel_updates',
      'Parcel Updates',
      description: 'Notifications for parcel request updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(parcelChannel);
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
      if (_currentToken != null) {
        if (kDebugMode) {
          print('[NotificationService] FCM Token retrieved: $_currentToken');
        }
      }
      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Manually retry getting FCM token
  /// Useful for iOS when APNS token becomes available after initial initialization
  Future<String?> retryGetToken() async {
    if (kDebugMode) {
      print('[NotificationService] Manually retrying FCM token retrieval...');
    }

    final token = await getToken();
    if (token != null) {
      await storeToken(token);
    }
    return token;
  }

  /// Store FCM token to Firestore users/{userId}/fcmTokens array
  Future<void> storeToken(String token) async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null) {
        if (kDebugMode) {
          print('[NotificationService] Cannot store token: No user logged in');
        }
        return;
      }

      await repository.storeFCMToken(userId, token);

      if (kDebugMode) {
        print('[NotificationService] FCM token stored for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error storing FCM token: $e');
      }
    }
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || _currentToken == null) return;

      await repository.removeFCMToken(userId, _currentToken!);

      if (kDebugMode) {
        print('[NotificationService] FCM token removed for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error removing FCM token: $e');
      }
    }
  }

  /// Handle foreground messages
  /// Subscribe to FirebaseMessaging.onMessage stream
  ///
  /// Notification display logic:
  /// - Chat messages: SKIP - ChatNotificationListener handles via Firestore real-time
  /// - Escrow/Parcel updates: SHOW - No dedicated listener, need FCM notification
  ///
  /// This prevents duplicate chat notifications while ensuring escrow updates are shown.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('[NotificationService] Foreground message received: ${message.messageId}');
      }

      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null) return;

      // Extract notification data
      final notification = message.notification;
      final data = message.data;

      final title = notification?.title ?? data['title'] as String? ?? '';
      final body = notification?.body ?? data['body'] as String? ?? '';
      final chatId = data['chatId'] as String?;
      final parcelId = data['parcelId'] as String?;
      final travelerId = data['travelerId'] as String?;
      final travelerName = data['travelerName'] as String?;
      final type = data['type'] as String?;

      // Only skip chat_message type - these are handled by ChatNotificationListener.
      // Show all other notifications (escrow, parcel updates, etc.) in foreground.
      final isChatMessage = type == 'chat_message';

      if (isChatMessage) {
        if (kDebugMode) {
          print('[NotificationService] Skipping chat notification - handled by ChatNotificationListener');
        }
      } else {
        // Display local notification for non-chat messages (escrow, parcel updates, etc.)
        await _displayLocalNotification(
          message: message,
          title: title,
          body: body,
          chatId: chatId,
          parcelId: parcelId,
          travelerId: travelerId,
          travelerName: travelerName,
        );
      }

      // Save notification to Firestore for in-app notification center (all types)
      final notificationModel = NotificationModel.fromRemoteMessage(
        message,
        userId,
      );
      await remoteDataSource.saveNotification(notificationModel);

      // Update badge count
      await _updateBadgeCount();

      if (kDebugMode) {
        print('[NotificationService] Foreground message processed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error handling foreground message: $e');
      }
    }
  }

  /// Display local notification using flutter_local_notifications
  Future<void> _displayLocalNotification({
    required RemoteMessage message,
    required String title,
    required String body,
    String? chatId,
    String? parcelId,
    String? travelerId,
    String? travelerName,
  }) async {
    // Detect notification type from data
    final type = message.data['type'] as String?;
    final isParcelNotification = type == 'parcel_request_accepted' ||
        type == 'delivery_confirmation_required';

    // Use appropriate channel based on notification type
    final androidDetails = AndroidNotificationDetails(
      isParcelNotification ? 'parcel_updates' : 'chat_messages',
      isParcelNotification ? 'Parcel Updates' : 'Chat Messages',
      channelDescription: isParcelNotification
          ? 'Notifications for parcel request updates'
          : 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      groupKey: isParcelNotification ? 'parcel_group' : 'chat_group',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload with appropriate fields for navigation
    final payload = jsonEncode({
      if (chatId != null) 'chatId': chatId,
      if (parcelId != null) 'parcelId': parcelId,
      if (travelerId != null) 'travelerId': travelerId,
      if (travelerName != null) 'travelerName': travelerName,
      if (type != null) 'type': type,
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
        print('[NotificationService] Background message handler: ${message.messageId}');
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
        print('[NotificationService] Background notification displayed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error handling background message: $e');
      }
    }
  }

  /// Handle notification tap
  /// Parse notification payload JSON and navigate to appropriate screen
  Future<void> handleNotificationTap(NotificationResponse response) async {
    try {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) {
        if (kDebugMode) {
          print('[NotificationService] Notification tapped with no payload');
        }
        return;
      }

      // Parse payload JSON
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final chatId = data['chatId'] as String?;
      final parcelId = data['parcelId'] as String?;
      final notificationId = data['notificationId'] as String?;

      if (kDebugMode) {
        print('[NotificationService] Notification tapped - chatId: $chatId, parcelId: $parcelId');
      }

      // Mark notification as read if notificationId exists
      if (notificationId != null) {
        await remoteDataSource.markAsRead(notificationId);
        // Update badge count after marking as read
        await _updateBadgeCount();
      }

      // Navigate to appropriate screen based on notification type
      // Priority: parcelId > chatId
      if (parcelId != null) {
        // Navigate to RequestDetailsScreen with parcelId parameter
        await navigationService.navigateTo(
          Routes.requestDetails,
          arguments: {'parcelId': parcelId},
        );
      } else if (chatId != null) {
        // Navigate to ChatScreen with chatId parameter
        await navigationService.navigateTo(
          Routes.chat,
          arguments: {'chatId': chatId},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error handling notification tap: $e');
      }
    }
  }

  /// Request notification permissions
  Future<AuthorizationStatus> requestPermissions() async {
    try {
      final status = await repository.requestPermissions();

      if (kDebugMode) {
        print('[NotificationService] Notification permission status: $status');
      }

      return status;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error requesting notification permissions: $e');
      }
      return AuthorizationStatus.denied;
    }
  }

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await repository.subscribeToTopic(topic);
      if (kDebugMode) {
        print('[NotificationService] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await repository.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('[NotificationService] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error unsubscribing from topic $topic: $e');
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
        print('[NotificationService] Error getting unread count: $e');
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
        print('[NotificationService] Error updating badge count: $e');
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
          print('[NotificationService] Badge count updated to: $count');
        }
      } else {
        if (kDebugMode) {
          print('[NotificationService] App badges not supported on this device');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error updating badge count: $e');
      }
    }
  }

  /// Show local notification for a chat message
  /// Returns true if notification was shown, false if suppressed
  Future<bool> showChatMessageNotification({
    required String chatId,
    required String messageId,
    required String senderName,
    required String messagePreview,
    String? senderAvatar,
  }) async {
    // Skip if user is currently viewing this chat
    if (_currentChatId == chatId) {
      if (kDebugMode) {
        print('[NotificationService] Suppressing notification - user viewing chat: $chatId');
      }
      return false;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
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

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({
        'chatId': chatId,
        'messageId': messageId,
        'type': 'chat_message',
      });

      await localNotifications.show(
        messageId.hashCode,
        senderName,
        messagePreview,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        print('[NotificationService] Chat notification shown for message: $messageId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error showing chat notification: $e');
      }
      return false;
    }
  }

  /// Clear app badge (set to 0)
  Future<void> clearBadge() async {
    try {
      await AppBadgePlus.updateBadge(0);
      if (kDebugMode) {
        print('[NotificationService] Badge cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error clearing badge: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
  }
}
