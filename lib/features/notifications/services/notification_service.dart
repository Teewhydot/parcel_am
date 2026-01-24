import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../domain/usecases/notification_usecase.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/models/notification_model.dart';
import '../../../core/routes/routes.dart';
import '../../../core/services/navigation_service/nav_config.dart';
import '../../../core/utils/logger.dart' show Logger, LogTag;
import '../domain/repositories/fcm_repository.dart';
import '../domain/repositories/notification_settings_repository.dart';
import '../domain/entities/notification_settings_entity.dart';
import '../../chat/services/typing_service.dart';

/// Top-level background message handler
/// Must be a top-level function for Firebase Messaging background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate if not already initialized
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Already initialized, ignore
  }

  // Display notification from background handler
  await _showBackgroundNotification(message);
}

/// Helper function to display notification from background
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  final data = message.data;
  final type = data['type'] as String?;
  final chatId = data['chatId'] as String?;
  final messageId = data['messageId'] as String?;

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

  final title = notification?.title ?? data['title'] as String? ?? '';
  final body = notification?.body ?? data['body'] as String? ?? '';

  // Detect notification type from data payload
  final parcelId = data['parcelId'] as String?;
  final travelerId = data['travelerId'] as String?;
  final travelerName = data['travelerName'] as String?;

  // Use appropriate channel based on notification type
  final isParcelNotification =
      type == 'parcel_request_accepted' ||
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
    if (messageId != null) 'messageId': messageId,
    if (parcelId != null) 'parcelId': parcelId,
    if (travelerId != null) 'travelerId': travelerId,
    if (travelerName != null) 'travelerName': travelerName,
    if (type != null) 'type': type,
  });

  // Use a consistent notification ID based on the actual message content
  // This ensures duplicate FCM deliveries update the same notification
  // instead of creating multiple notifications
  final notificationId =
      messageId?.hashCode ??
      chatId?.hashCode ??
      parcelId?.hashCode ??
      message.messageId?.hashCode ??
      DateTime.now().millisecondsSinceEpoch;

  await localNotifications.show(
    notificationId,
    title,
    body,
    notificationDetails,
    payload: payload,
  );

  // Mark notification as sent for chat messages
  if (type == 'chat_message' && chatId != null && messageId != null) {
    await _markNotificationSentInBackground(chatId, messageId);
  }
}

/// Mark notification as sent in Firestore (for background handler)
/// Supports paged message structure: chats/{chatId}/pages/{pageId}/messages[]
Future<void> _markNotificationSentInBackground(
  String chatId,
  String messageId,
) async {
  
    final firestore = FirebaseFirestore.instance;

    // Find and update the message in pages
    final pagesQuery = await firestore
        .collection('chats')
        .doc(chatId)
        .collection('pages')
        .orderBy('pageNumber', descending: true)
        .limit(3) // Check the 3 most recent pages
        .get();

    bool found = false;
    for (final pageDoc in pagesQuery.docs) {
      final messages = pageDoc.data()['messages'] as List<dynamic>? ?? [];
      final messageIndex = messages.indexWhere(
        (msg) => msg is Map<String, dynamic> && msg['id'] == messageId,
      );

      if (messageIndex >= 0) {
        // Found the message, update notificationSent flag
        final updatedMessages = List<dynamic>.from(messages);
        final msgMap = Map<String, dynamic>.from(
          updatedMessages[messageIndex] as Map,
        );
        msgMap['notificationSent'] = true;
        updatedMessages[messageIndex] = msgMap;

        await pageDoc.reference.update({
          'messages': updatedMessages,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        found = true;
        break;
      }
    }

    // Fallback: try old structure for backward compatibility
    if (!found) {
      try {
        await firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({'notificationSent': true});
      } catch (e) {
        // Old structure doesn't exist, that's fine
      }
    }
  
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
  final NotificationSettingsRepository settingsRepository;

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
    required this.settingsRepository,
  });

  /// Get singleton instance
  factory NotificationService.getInstance({
    required FCMRepository repository,
    required FlutterLocalNotificationsPlugin localNotifications,
    required NotificationRemoteDataSource remoteDataSource,
    required NavigationService navigationService,
    required FirebaseAuth firebaseAuth,
    required NotificationSettingsRepository settingsRepository,
  }) {
    _instance ??= NotificationService(
      repository: repository,
      localNotifications: localNotifications,
      remoteDataSource: remoteDataSource,
      navigationService: navigationService,
      firebaseAuth: firebaseAuth,
      settingsRepository: settingsRepository,
    );
    return _instance!;
  }

  bool get isInitialized => _isInitialized;
  String? get currentToken => _currentToken;

  /// Get user's notification settings
  /// Returns default settings if user is not logged in or settings fetch fails
  Future<NotificationSettingsEntity> _getUserSettings() async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return NotificationSettingsEntity.defaultSettings();
    }

    final result = await settingsRepository.getSettings(userId);
    return result.fold(
      (_) => NotificationSettingsEntity.defaultSettings(),
      (settings) => settings,
    );
  }

  /// Check if a notification type should be shown based on user settings
  Future<bool> _shouldShowNotification(String? notificationType) async {
    final settings = await _getUserSettings();

    switch (notificationType) {
      case 'chat_message':
        return settings.chatMessages;
      case 'parcel_request_accepted':
      case 'delivery_confirmation_required':
      case 'parcel_update':
        return settings.parcelUpdates;
      case 'escrow_update':
      case 'payment_received':
      case 'payment_released':
        return settings.escrowAlerts;
      case 'system_announcement':
      case 'app_update':
        return settings.systemAnnouncements;
      default:
        // For unknown types, show by default
        return true;
    }
  }

  /// Initialize notification service
  /// Called from main.dart after Firebase initialization, before runApp
  Future<void> initialize() async {
    if (_isInitialized) {
      Logger.logBasic('NotificationService already initialized, skipping', tag: LogTag.notification);
      return;
    }

    Logger.logBasic('Initializing NotificationService...', tag: LogTag.notification);

    try {
      // Request notification permissions for iOS/web
      if (Platform.isIOS || kIsWeb) {
        Logger.logBasic('Requesting notification permissions for ${Platform.isIOS ? 'iOS' : 'Web'}', tag: LogTag.notification);
        await requestPermissions();
      }

      // Initialize flutter_local_notifications with platform-specific settings
      Logger.logBasic('Initializing local notifications', tag: LogTag.notification);
      await _initializeLocalNotifications();

      // Configure Android notification channels
      await _configureAndroidChannels();

      // Configure iOS/Darwin notification settings
      await _configureIOSSettings();

      // Subscribe to token refresh first (this will capture the token when it becomes available)
      _tokenRefreshSubscription = repository.onTokenRefresh.listen((newToken) {
        Logger.logBasic('FCM token refreshed', tag: LogTag.notification);
        _currentToken = newToken;
        storeToken(newToken);
      });

      // Get and store FCM token (may be null on iOS initially if APNS token not ready)
      final token = await getToken();
      if (token != null) {
        Logger.logSuccess('FCM token obtained: ${token.substring(0, 20)}...', tag: LogTag.notification);
        await storeToken(token);
      } else {
        Logger.logWarning('FCM token is null (APNS may not be ready on iOS)', tag: LogTag.notification);
      }

      // Subscribe to foreground messages
      _foregroundMessageSubscription = repository.onForegroundMessage.listen(
        handleForegroundMessage,
      );

      _isInitialized = true;
      Logger.logSuccess('NotificationService initialized successfully', tag: LogTag.notification);
    } catch (e) {
      Logger.logError('Failed to initialize NotificationService: $e', tag: LogTag.notification);
      rethrow;
    }
  }

  /// Initialize local notifications with platform-specific settings
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(parcelChannel);
  }

  /// Configure iOS/Darwin notification settings
  Future<void> _configureIOSSettings() async {
    if (!Platform.isIOS) return;

    await localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Get FCM token
  Future<String?> getToken() async {
    final result = await repository.getFCMToken();
    return result.fold(
      (failure) => null,
      (token) {
        _currentToken = token;
        return _currentToken;
      },
    );
  }

  /// Manually retry getting FCM token
  /// Useful for iOS when APNS token becomes available after initial initialization
  Future<String?> retryGetToken() async {
    final token = await getToken();
    if (token != null) {
      await storeToken(token);
    }
    return token;
  }

  /// Store FCM token to Firestore users/{userId}/fcmTokens array
  Future<void> storeToken(String token) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return;
    }

    await repository.storeFCMToken(userId, token);
    // Fire-and-forget: result not needed, errors are silently handled
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || _currentToken == null) return;

    await repository.removeFCMToken(userId, _currentToken!);
    // Fire-and-forget: result not needed, errors are silently handled
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
    Logger.logBasic('Received foreground message: ${message.messageId}', tag: LogTag.notification);
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null) {
        Logger.logWarning('No user logged in, ignoring foreground message', tag: LogTag.notification);
        return;
      }

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

      Logger.logBasic('Foreground message type: $type, title: $title', tag: LogTag.notification);

      // Only skip chat_message type - these are handled by ChatNotificationListener.
      // Show all other notifications (escrow, parcel updates, etc.) in foreground.
      final isChatMessage = type == 'chat_message';

      if (!isChatMessage) {
        // Check user's notification settings before displaying
        final shouldShow = await _shouldShowNotification(type);
        Logger.logBasic('Should show notification for type $type: $shouldShow', tag: LogTag.notification);
        if (shouldShow) {
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
          Logger.logSuccess('Displayed local notification: $title', tag: LogTag.notification);
        }
      } else {
        Logger.logBasic('Skipping chat message notification (handled by ChatNotificationListener)', tag: LogTag.notification);
      }

      // Save notification to Firestore for in-app notification center (all types)
      final notificationModel = NotificationModel.fromRemoteMessage(
        message,
        userId,
      );
      await remoteDataSource.saveNotification(notificationModel);
      Logger.logBasic('Saved notification to Firestore', tag: LogTag.notification);

      // Update badge numCount
      await _updateBadgenumCount();
    } catch (e) {
      Logger.logError('Error handling foreground message: $e', tag: LogTag.notification);
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
    final isParcelNotification =
        type == 'parcel_request_accepted' ||
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

      // Extract chat details from data payload
      final data = message.data;
      final notification = message.notification;

      final senderName = data['senderName'] as String? ?? 'Someone';
      final messageContent =
          notification?.body ?? data['body'] as String? ?? '';
      final chatId = data['chatId'] as String?;

      // Display local notification from background handler
      final androidDetails = AndroidNotificationDetails(
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

      final notificationDetails = NotificationDetails(
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

  }

  /// Handle notification tap
  /// Parse notification payload JSON and navigate to appropriate screen
  Future<void> handleNotificationTap(NotificationResponse response) async {
    Logger.logBasic('Notification tapped', tag: LogTag.notification);
    try {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) {
        Logger.logWarning('Notification tap with empty payload', tag: LogTag.notification);
        return;
      }

      // Parse payload JSON
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final chatId = data['chatId'] as String?;
      final parcelId = data['parcelId'] as String?;
      final notificationId = data['notificationId'] as String?;

      Logger.logBasic('Notification payload: chatId=$chatId, parcelId=$parcelId', tag: LogTag.notification);

      // Mark notification as read if notificationId exists
      if (notificationId != null) {
        await remoteDataSource.markAsRead(notificationId);
        // Update badge numCount after marking as read
        await _updateBadgenumCount();
      }

      // Navigate to appropriate screen based on notification type
      // Priority: parcelId > chatId
      if (parcelId != null) {
        Logger.logBasic('Navigating to request details: $parcelId', tag: LogTag.notification);
        // Navigate to RequestDetailsScreen with parcelId parameter
        await navigationService.navigateTo(
          Routes.requestDetails,
          arguments: {'parcelId': parcelId},
        );
      } else if (chatId != null) {
        Logger.logBasic('Navigating to chat: $chatId', tag: LogTag.notification);
        // Navigate to ChatScreen with chatId parameter
        await navigationService.navigateTo(
          Routes.chat,
          arguments: {'chatId': chatId},
        );
      }
    } catch (e) {
      Logger.logError('Error handling notification tap: $e', tag: LogTag.notification);
    }
  }

  /// Request notification permissions
  Future<AuthorizationStatus> requestPermissions() async {
    Logger.logBasic('Requesting notification permissions...', tag: LogTag.notification);
    final result = await repository.requestPermissions();
    return result.fold(
      (failure) {
        Logger.logError('Permission request failed: ${failure.failureMessage}', tag: LogTag.notification);
        return AuthorizationStatus.denied;
      },
      (status) {
        Logger.logSuccess('Permission status: $status', tag: LogTag.notification);
        return status;
      },
    );
  }

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    await repository.subscribeToTopic(topic);
    // Fire-and-forget: result not needed, errors are silently handled
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await repository.unsubscribeFromTopic(topic);
    // Fire-and-forget: result not needed, errors are silently handled
  }

  /// Calculate total unread notification numCount from Firestore
  Future<int> _getTotalUnreadnumCount() async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) return 0;

    final result = await repository.getUnreadNotificationCount(userId);
    return result.fold(
      (failure) => 0,
      (numCount) => numCount,
    );
  }

  /// Update app badge numCount based on total unread notifications
  Future<void> _updateBadgenumCount() async {
    try {
      final unreadnumCount = await _getTotalUnreadnumCount();
      await updateBadgenumCount(unreadnumCount);
    } catch (e) {
      // Silent catch
    }
  }

  /// Update app badge numCount
  /// This method can also be called publicly to manually update badge
  Future<void> updateBadgenumCount(int numCount) async {
    try {
      // Check if the device supports app badges
      final isSupported = await AppBadgePlus.isSupported();

      if (isSupported) {
        await AppBadgePlus.updateBadge(numCount);
      }
    } catch (e) {
      // Silent catch
    }
  }

  /// Show local notification for a chat message
  /// Returns true if notification was shown, false if suppressed
  /// [userId] - The current user's ID (from context.currentUserId)
  Future<bool> showChatMessageNotification({
    required String chatId,
    required String messageId,
    required String senderName,
    required String messagePreview,
    required String userId,
    String? senderAvatar,
  }) async {
    Logger.logBasic('showChatMessageNotification: chatId=$chatId, sender=$senderName', tag: LogTag.notification);

    // Check if user is currently viewing this chat using RTDB (more reliable than local state)
    final isViewing = await TypingService().isUserViewingChat(userId, chatId);
    if (isViewing) {
      Logger.logBasic('Skipping notification - user is viewing this chat (RTDB)', tag: LogTag.notification);
      return false;
    }

    // Check user's notification settings for chat messages
    final shouldShow = await _shouldShowNotification('chat_message');
    if (!shouldShow) {
      Logger.logBasic('Skipping notification - disabled in settings', tag: LogTag.notification);
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

      Logger.logSuccess('Chat notification displayed: $senderName', tag: LogTag.notification);
      return true;
    } catch (e) {
      Logger.logError('Failed to show chat notification: $e', tag: LogTag.notification);
      return false;
    }
  }

  /// Clear app badge (set to 0)
  Future<void> clearBadge() async {
    try {
      await AppBadgePlus.updateBadge(0);
    } catch (e) {
      // Silent catch
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
  }
}
