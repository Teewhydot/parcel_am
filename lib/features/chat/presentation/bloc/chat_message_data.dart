import '../../domain/entities/message.dart';
import '../../domain/entities/chat.dart';

/// Data class for ChatCubit state (single chat conversation)
class ChatMessageData {
  final List<Message> messages;
  final Chat? chat;
  final Message? replyToMessage;
  final double uploadProgress;
  final bool isUploading;

  const ChatMessageData({
    this.messages = const [],
    this.chat,
    this.replyToMessage,
    this.uploadProgress = 0.0,
    this.isUploading = false,
  });

  ChatMessageData copyWith({
    List<Message>? messages,
    Chat? chat,
    Message? replyToMessage,
    bool clearReplyToMessage = false,
    double? uploadProgress,
    bool? isUploading,
  }) {
    return ChatMessageData(
      messages: messages ?? this.messages,
      chat: chat ?? this.chat,
      replyToMessage:
          clearReplyToMessage ? null : (replyToMessage ?? this.replyToMessage),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}
