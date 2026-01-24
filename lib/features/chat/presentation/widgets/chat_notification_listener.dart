import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart' show Logger, LogTag;
import '../../../../injection_container.dart' as di;
import '../../../notifications/services/notification_service.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/usecases/chat_usecase.dart';

/// Widget that listens to all user chats and shows local notifications
/// for new messages when the user is not viewing that specific chat.
class ChatNotificationListener extends StatefulWidget {
  final String userId;
  final Widget child;

  const ChatNotificationListener({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  State<ChatNotificationListener> createState() =>
      _ChatNotificationListenerState();
}

class _ChatNotificationListenerState extends State<ChatNotificationListener> {
  final ChatUseCase _chatUseCase = ChatUseCase();
  StreamSubscription<List<Chat>>? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(covariant ChatNotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _stopListening();
      _startListening();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  void _startListening() {
    _chatsSubscription = _chatUseCase.repository
        .watchUserChats(widget.userId)
        .listen(_handleChatsUpdate);
  }

  void _stopListening() {
    _chatsSubscription?.cancel();
    _chatsSubscription = null;
  }

  void _handleChatsUpdate(List<Chat> chats) {
    for (final chat in chats) {
      _checkForNewMessage(chat);
    }
  }

  void _checkForNewMessage(Chat chat) {
    final lastMessage = chat.lastMessage;
    if (lastMessage == null) return;

    // Skip if this is from the current user
    if (lastMessage.senderId == widget.userId) return;

    // Skip if notification was already sent (from Firestore flag)
    if (lastMessage.notificationSent) return;

    // Try to show notification (will atomically claim it)
    _showNotificationForMessage(chat, lastMessage);
  }

  Future<void> _showNotificationForMessage(Chat chat, Message message) async {
    try {
      // Atomically try to claim this notification
      // Returns false if another instance already claimed it
      final claimed = await _chatUseCase.repository.tryClaimNotification(
        chat.id,
        message.id,
      );

      if (!claimed) {
        // Already claimed by another process/instance, skip
        return;
      }

      final notificationService = di.sl<NotificationService>();

      // Get sender name from chat participants
      final senderName = chat.participantNames[message.senderId] ??
          message.senderName;

      // Create message preview
      String messagePreview;
      switch (message.type) {
        case MessageType.image:
          messagePreview = '📷 Photo';
        case MessageType.video:
          messagePreview = '🎥 Video';
        case MessageType.document:
          messagePreview = '📄 ${message.fileName ?? 'Document'}';
        case MessageType.text:
          messagePreview = message.content.length > 100
              ? '${message.content.substring(0, 100)}...'
              : message.content;
      }

      final shown = await notificationService.showChatMessageNotification(
        chatId: chat.id,
        messageId: message.id,
        senderName: senderName,
        messagePreview: messagePreview,
        userId: widget.userId,
        senderAvatar: message.senderAvatar,
      );

      if (shown) {
        Logger.logSuccess(
          'Notification shown for message ${message.id}',
          tag: LogTag.notification,
        );
      }
    } catch (e) {
      Logger.logError(
        'Failed to show notification: $e',
        tag: LogTag.notification,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
