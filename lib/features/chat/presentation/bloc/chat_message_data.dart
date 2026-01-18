import '../../domain/entities/message.dart';
import '../../domain/entities/chat.dart';

/// Data class for ChatCubit state (single chat conversation)
/// Note: This is different from ChatData which is for the chat list
class ChatMessageData {
  final List<Message> messages;
  final Chat? chat;
  final Message? replyToMessage;
  final double uploadProgress;
  final bool isUploading;
  final bool isSending;

  const ChatMessageData({
    this.messages = const [],
    this.chat,
    this.replyToMessage,
    this.uploadProgress = 0.0,
    this.isUploading = false,
    this.isSending = false,
  });

  ChatMessageData copyWith({
    List<Message>? messages,
    Chat? chat,
    Message? replyToMessage,
    bool clearReplyToMessage = false,
    double? uploadProgress,
    bool? isUploading,
    bool? isSending,
  }) {
    return ChatMessageData(
      messages: messages ?? this.messages,
      chat: chat ?? this.chat,
      replyToMessage:
          clearReplyToMessage ? null : (replyToMessage ?? this.replyToMessage),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      isSending: isSending ?? this.isSending,
    );
  }
}
