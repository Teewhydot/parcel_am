import '../../domain/entities/message.dart';
import '../../domain/entities/chat.dart';

/// Data class for ChatCubit state (single chat conversation)
/// Note: This is different from ChatData which is for the chat list
class ChatMessageData {
  final List<Message> messages;
  final List<Message> pendingMessages; // Optimistic messages not yet confirmed
  final Chat? chat;
  final Message? replyToMessage;
  final double uploadProgress;
  final bool isUploading;

  const ChatMessageData({
    this.messages = const [],
    this.pendingMessages = const [],
    this.chat,
    this.replyToMessage,
    this.uploadProgress = 0.0,
    this.isUploading = false,
  });

  /// Get all messages merged (pending + confirmed), sorted by timestamp descending
  List<Message> get allMessages {
    // Filter out pending messages that are now in the confirmed list
    final confirmedIds = messages.map((m) => m.id).toSet();
    final stillPending = pendingMessages.where((p) =>
      !confirmedIds.contains(p.id) &&
      !messages.any((m) => _isSameMessage(m, p))
    ).toList();

    // Merge and sort by timestamp (descending for reverse list)
    final merged = [...stillPending, ...messages];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  /// Check if two messages are the same (for matching temp IDs with real IDs)
  static bool _isSameMessage(Message a, Message b) {
    // Match by content, sender, and close timestamp (within 5 seconds)
    return a.senderId == b.senderId &&
        a.content == b.content &&
        a.type == b.type &&
        (a.timestamp.difference(b.timestamp).inSeconds.abs() < 5);
  }

  ChatMessageData copyWith({
    List<Message>? messages,
    List<Message>? pendingMessages,
    Chat? chat,
    Message? replyToMessage,
    bool clearReplyToMessage = false,
    double? uploadProgress,
    bool? isUploading,
  }) {
    return ChatMessageData(
      messages: messages ?? this.messages,
      pendingMessages: pendingMessages ?? this.pendingMessages,
      chat: chat ?? this.chat,
      replyToMessage:
          clearReplyToMessage ? null : (replyToMessage ?? this.replyToMessage),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}
