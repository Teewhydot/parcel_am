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
    }
  }

  /// Stream for watching chat details - use with StreamBuilder
  Stream<Either<Failure, Chat>> watchChat(String chatId) async* {
    try {
      yield* chatUseCase.getChatStream(chatId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
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

    // Show async loading state while preserving current data
    emit(AsyncLoadingState<ChatMessageData>(data: currentData));

    final result = await chatUseCase.sendMessage(message);

    result.fold(
      (failure) {
        emit(AsyncErrorState<ChatMessageData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (_) {
        // Clear reply-to message after successful send
        final updatedData = currentData.copyWith(clearReplyToMessage: true);
        emit(LoadedState<ChatMessageData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
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

  Future<void> deleteMessage(String messageId) async {
    final currentData = state.data ?? const ChatMessageData();
    emit(AsyncLoadingState<ChatMessageData>(data: currentData));

    final result = await chatUseCase.deleteMessage(messageId);

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
