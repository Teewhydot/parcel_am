import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class MessagesLoaded extends ChatState {
  final List<Message> messages;
  final Chat? chat;
  final Message? replyToMessage;
  final double uploadProgress;
  final bool isUploading;

  const MessagesLoaded({
    required this.messages,
    this.chat,
    this.replyToMessage,
    this.uploadProgress = 0.0,
    this.isUploading = false,
  });

  @override
  List<Object?> get props => [
        messages,
        chat,
        replyToMessage,
        uploadProgress,
        isUploading,
      ];

  MessagesLoaded copyWith({
    List<Message>? messages,
    Chat? chat,
    Message? replyToMessage,
    bool clearReplyToMessage = false,
    double? uploadProgress,
    bool? isUploading,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      chat: chat ?? this.chat,
      replyToMessage: clearReplyToMessage ? null : (replyToMessage ?? this.replyToMessage),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

class MessageSending extends ChatState {
  final Message message;

  const MessageSending(this.message);

  @override
  List<Object> get props => [message];
}

class MessageSent extends ChatState {
  final Message message;

  const MessageSent(this.message);

  @override
  List<Object> get props => [message];
}

class MediaUploading extends ChatState {
  final double progress;

  const MediaUploading(this.progress);

  @override
  List<Object> get props => [progress];
}
