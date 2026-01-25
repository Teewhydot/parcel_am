import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/bloc/base/base_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/chat_usecase.dart';
import 'chat_message_data.dart';

class ChatCubit extends BaseCubit<BaseState<ChatMessageData>> {
  final chatUseCase = ChatUseCase();
  static const _uuid = Uuid();

  ChatCubit() : super(const InitialState<ChatMessageData>());

  /// Stream for watching messages - use with StreamBuilder
  Stream<Either<Failure, List<Message>>> watchMessages(String chatId) async* {
    try {
      yield* chatUseCase.getMessagesStream(chatId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  /// Stream for watching chat details - use with StreamBuilder
  Stream<Either<Failure, Chat>> watchChat(String chatId) async* {
    try {
      yield* chatUseCase.getChatStream(chatId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  void setLoadingState() {
    emit(const LoadingState<ChatMessageData>());
  }

  /// Updates messages by merging with existing ones
  /// - If message ID exists: update it (status change)
  /// - If message ID is new: add it
  void updateMessages(List<Message> incomingMessages) {
    final currentData = state.data ?? const ChatMessageData();
    final currentMessages = List<Message>.from(currentData.messages);

    // Build a map of current messages by ID for quick lookup
    final messageMap = {for (var m in currentMessages) m.id: m};

    // Merge incoming messages
    for (final incoming in incomingMessages) {
      final existing = messageMap[incoming.id];
      if (existing != null) {
        // Preserve replyToMessage from either source (prefer server, fallback to local)
        final replyToMessage = incoming.replyToMessage ?? existing.replyToMessage;

        // Update existing message with server data, preserving reply
        final mergedMessage = incoming.replyToMessage != null
            ? incoming
            : incoming.copyWith(replyToMessage: replyToMessage);

        if (existing.status == MessageStatus.sending &&
            incoming.status == MessageStatus.sent) {
          // Server confirmed - update to server version
          messageMap[incoming.id] = mergedMessage;
        } else if (existing.status != MessageStatus.sending) {
          // Normal update from server
          messageMap[incoming.id] = mergedMessage;
        }
        // If still "sending" locally, keep local version (with replyToMessage intact)
      } else {
        // New message from server (e.g., from other user)
        messageMap[incoming.id] = incoming;
      }
    }

    // Convert back to list and sort by timestamp (oldest first for chat display)
    final mergedMessages = messageMap.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    emit(LoadedState<ChatMessageData>(
      data: currentData.copyWith(messages: mergedMessages),
      lastUpdated: DateTime.now(),
    ));
  }

  void updateChat(Chat chat) {
    final currentData = state.data ?? const ChatMessageData();
    emit(LoadedState<ChatMessageData>(
      data: currentData.copyWith(chat: chat),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> sendMessage(Message message) async {
    final currentData = state.data ?? const ChatMessageData();

    // Generate a unique ID for this message
    final messageId = _uuid.v4();

    // Create message with the generated ID and "sending" status
    final outgoingMessage = Message(
      id: messageId,
      chatId: message.chatId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: message.content,
      type: message.type,
      status: MessageStatus.sending,
      timestamp: message.timestamp,
      mediaUrl: message.mediaUrl,
      thumbnailUrl: message.thumbnailUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      replyToMessageId: message.replyToMessageId,
      replyToMessage: message.replyToMessage,
    );

    // Add to messages list immediately (optimistic update)
    final updatedMessages = [...currentData.messages, outgoingMessage]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    emit(LoadedState<ChatMessageData>(
      data: currentData.copyWith(
        messages: updatedMessages,
        clearReplyToMessage: true,
      ),
      lastUpdated: DateTime.now(),
    ));

    // Send to server (pass participantIds to avoid read operation for lower latency)
    final participantIds = currentData.chat?.participantIds;
    final result = await chatUseCase.sendMessage(
      outgoingMessage,
      participantIds: participantIds,
    );

    result.fold(
      (failure) {
        // Mark message as failed
        final messages = (state.data ?? currentData).messages.map((m) {
          if (m.id == messageId) {
            return Message(
              id: m.id,
              chatId: m.chatId,
              senderId: m.senderId,
              senderName: m.senderName,
              senderAvatar: m.senderAvatar,
              content: m.content,
              type: m.type,
              status: MessageStatus.failed,
              timestamp: m.timestamp,
              mediaUrl: m.mediaUrl,
              thumbnailUrl: m.thumbnailUrl,
              fileName: m.fileName,
              fileSize: m.fileSize,
              replyToMessageId: m.replyToMessageId,
              replyToMessage: m.replyToMessage,
            );
          }
          return m;
        }).toList();

        emit(AsyncErrorState<ChatMessageData>(
          errorMessage: failure.failureMessage,
          data: (state.data ?? currentData).copyWith(messages: messages),
        ));
      },
      (_) {
        // Success - stream will update the message status
        // No action needed here
      },
    );
  }

  Future<void> sendMediaMessage({
    required String filePath,
    required String chatId,
    required MessageType type,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    String? replyToMessageId,
  }) async {
    final currentData = state.data ?? const ChatMessageData();

    // Set uploading state
    emit(LoadedState<ChatMessageData>(
      data: currentData.copyWith(
        isUploading: true,
        uploadProgress: 0.0,
      ),
      lastUpdated: DateTime.now(),
    ));

    final uploadResult = await chatUseCase.uploadMedia(
      filePath,
      chatId,
      type,
      (progress) {
        emit(LoadedState<ChatMessageData>(
          data: (state.data ?? currentData).copyWith(
            uploadProgress: progress,
            isUploading: true,
          ),
          lastUpdated: DateTime.now(),
        ));
      },
    );

    await uploadResult.fold(
      (failure) async {
        emit(AsyncErrorState<ChatMessageData>(
          errorMessage: failure.failureMessage,
          data: (state.data ?? currentData).copyWith(isUploading: false),
        ));
      },
      (mediaUrl) async {
        final fileName = filePath.split('/').last;

        final message = Message(
          id: '', // Will be generated in sendMessage
          chatId: chatId,
          senderId: senderId,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: type == MessageType.document ? fileName : '',
          type: type,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          mediaUrl: mediaUrl,
          fileName: type == MessageType.document ? fileName : null,
          replyToMessageId: replyToMessageId,
        );

        try {
          await sendMessage(message);
        } finally {
          // Always reset uploading state, even if sendMessage fails
          emit(LoadedState<ChatMessageData>(
            data: (state.data ?? const ChatMessageData()).copyWith(
              isUploading: false,
              uploadProgress: 0.0,
            ),
            lastUpdated: DateTime.now(),
          ));
        }
      },
    );
  }

  Future<void> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    await chatUseCase.markMessageAsRead(chatId, messageId, userId);
  }

  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    await chatUseCase.setTypingStatus(chatId, userId, isTyping);
  }

  Future<void> updateLastSeen(String chatId, String userId) async {
    await chatUseCase.updateLastSeen(chatId, userId);
  }

  void setReplyToMessage(Message? message) {
    final currentData = state.data ?? const ChatMessageData();
    emit(LoadedState<ChatMessageData>(
      data: currentData.copyWith(
        replyToMessage: message,
        clearReplyToMessage: message == null,
      ),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> deleteMessage(String messageId, {String? chatId}) async {
    final currentData = state.data ?? const ChatMessageData();
    emit(AsyncLoadingState<ChatMessageData>(data: currentData));

    final result = await chatUseCase.deleteMessage(messageId, chatId: chatId);

    result.fold(
      (failure) {
        emit(AsyncErrorState<ChatMessageData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (_) {
        emit(LoadedState<ChatMessageData>(
          data: currentData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }
}
