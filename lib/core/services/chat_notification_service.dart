import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/repositories/chat_notification_repository.dart';

class ChatNotificationService {
  final ChatNotificationRepository _repository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  String? _currentUserId;

  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  ChatNotificationService({
    required ChatNotificationRepository repository,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  })  : _repository = repository,
        _notificationsPlugin = notificationsPlugin;

  Future<void> initialize(String userId) async {
    _currentUserId = userId;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _subscribeToChats();
  }

  void _subscribeToChats() {
    if (_currentUserId == null) return;

    _chatSubscription = _repository
        .watchUserChats(_currentUserId!)
        .listen(
      (snapshot) {
        // Calculate total unread count
        int totalUnread = 0;
        for (var doc in snapshot.docs) {
          final chatData = doc.data() as Map<String, dynamic>;
          final unreadCount =
              (chatData['unreadCount'] as Map<String, dynamic>?)?[_currentUserId] ?? 0;
          totalUnread += unreadCount as int;
        }
        _unreadCountController.add(totalUnread);

        // Handle chat updates for notifications
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final chatData = change.doc.data() as Map<String, dynamic>?;
            if (chatData != null) {
              _handleChatUpdate(change.doc.id, chatData);
            }
          }
        }
      },
    );
  }

  Future<void> _handleChatUpdate(
      String chatId, Map<String, dynamic> chatData) async {
    if (_currentUserId == null) return;

    final unreadCount =
        (chatData['unreadCount'] as Map<String, dynamic>?)?[_currentUserId] ??
            0;

    if (unreadCount > 0) {
      final lastMessage = chatData['lastMessage'] as String? ?? '';
      final participants = List<String>.from(chatData['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != _currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty) {
        final userData = await _repository.getUserData(otherUserId);
        final senderName = userData?['displayName'] ?? 'Someone';

        await _showNotification(
          chatId: chatId,
          senderName: senderName,
          message: lastMessage,
        );
      }
    }
  }

  Future<void> _showNotification({
    required String chatId,
    required String senderName,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    await _notificationsPlugin.show(
      chatId.hashCode,
      senderName,
      message,
      notificationDetails,
      payload: chatId,
    );
  }

  void dispose() {
    _chatSubscription?.cancel();
    _unreadCountController.close();
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}
