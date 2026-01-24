import 'package:dartz/dartz.dart';
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

  void updateMessages(List<Message> messages) {
    final currentData = state.data ?? const ChatMessageData();
    emit(LoadedState<ChatMessageData>(
      data: currentData.copyWith(messages: messages),
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

    // Optimistic update: Add message to pending list immediately
    final pendingMessage = Message(
      id: message.id,
      chatId: message.chatId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: message.content,
      type: message.type,
      status: MessageStatus.sending, // Show as sending
      timestamp: message.timestamp,
      mediaUrl: message.mediaUrl,
      thumbnailUrl: message.thumbnailUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      replyToMessageId: message.replyToMessageId,
      replyToMessage: message.replyToMessage,
    );

    // Add to pending and clear reply immediately for instant feedback
    emit(LoadedState<ChatMessageData>(
      data: currentData.copyWith(
        pendingMessages: [...currentData.pendingMessages, pendingMessage],
        clearReplyToMessage: true,
      ),
      lastUpdated: DateTime.now(),
    ));

    // Send message to server in background
    final result = await chatUseCase.sendMessage(message);

    result.fold(
      (failure) {
        // Update pending message status to failed
        final updatedPending = currentData.pendingMessages.map((m) {
          if (m.id == message.id) {
            return Message(
              id: m.id,
              chatId: m.chatId,
              senderId: m.senderId,
              senderName: m.senderName,
              senderAvatar: m.senderAvatar,
              content: m.content,
              type: m.type,
              status: MessageStatus.failed, // Mark as failed
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

        // Also add the failed message to show it
        updatedPending.add(Message(
          id: message.id,
          chatId: message.chatId,
          senderId: message.senderId,
          senderName: message.senderName,
          senderAvatar: message.senderAvatar,
          content: message.content,
          type: message.type,
          status: MessageStatus.failed,
          timestamp: message.timestamp,
          mediaUrl: message.mediaUrl,
          replyToMessageId: message.replyToMessageId,
        ));

        emit(AsyncErrorState<ChatMessageData>(
          errorMessage: failure.failureMessage,
          data: (state.data ?? currentData).copyWith(
            pendingMessages: updatedPending,
            clearReplyToMessage: true,
          ),
        ));
      },
      (_) {
        // Success - the stream will pick up the confirmed message
        // Pending message will be filtered out in allMessages getter
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
        final updatedData = currentData.copyWith(
          uploadProgress: progress,
          isUploading: true,
        );
        emit(LoadedState<ChatMessageData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );

    await uploadResult.fold(
      (failure) async {
        emit(AsyncErrorState<ChatMessageData>(
          errorMessage: failure.failureMessage,
          data: currentData.copyWith(isUploading: false),
        ));
      },
      (mediaUrl) async {
        final fileName = filePath.split('/').last;

        final message = Message(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
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

        await sendMessage(message);

        // Reset uploading state
        final resetData = (state.data ?? currentData).copyWith(
          isUploading: false,
          uploadProgress: 0.0,
        );
        emit(LoadedState<ChatMessageData>(
          data: resetData,
          lastUpdated: DateTime.now(),
        ));
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
