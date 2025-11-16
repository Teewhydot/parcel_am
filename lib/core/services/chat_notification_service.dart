import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatNotificationService {
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  String? _currentUserId;

  ChatNotificationService({
    required FirebaseFirestore firestore,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  })  : _firestore = firestore,
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

    _chatSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final chatData = change.doc.data();
            if (chatData != null) {
              _handleChatUpdate(change.doc.id, chatData);
            }
          }
        }
      },
      onError: (error) {
        print('❌ Firestore Error (ChatNotifications): $error');
        if (error.toString().contains('index')) {
          print('🔍 INDEX REQUIRED: Create a composite index for:');
          print('   Collection: chats');
          print('   Fields: participants (Array), [add other indexed fields]');
          print('   Or visit the Firebase Console to create the index automatically.');
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
        final userDoc =
            await _firestore.collection('users').doc(otherUserId).get();
        final userData = userDoc.data();
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
