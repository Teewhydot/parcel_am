import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/usecases/chat_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatUseCase chatUseCase;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _chatSubscription;

  ChatBloc({required this.chatUseCase}) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<SetTypingStatus>(_onSetTypingStatus);
    on<UpdateLastSeen>(_onUpdateLastSeen);
    on<SetReplyToMessage>(_onSetReplyToMessage);
    on<DeleteMessage>(_onDeleteMessage);
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    await _messagesSubscription?.cancel();

    _messagesSubscription = chatUseCase.getMessagesStream(event.chatId).listen(
      (result) {
        result.fold(
          (failure) => add(const LoadMessages('')),
          (messages) {
            if (state is MessagesLoaded) {
              emit((state as MessagesLoaded).copyWith(messages: messages));
            } else {
              emit(MessagesLoaded(messages: messages));
            }
          },
        );
      },
    );
  }

  Future<void> _onLoadChat(
    LoadChat event,
    Emitter<ChatState> emit,
  ) async {
    await _chatSubscription?.cancel();

    _chatSubscription = chatUseCase.getChatStream(event.chatId).listen(
      (result) {
        result.fold(
          (failure) => null,
          (chat) {
            if (state is MessagesLoaded) {
              emit((state as MessagesLoaded).copyWith(chat: chat));
            }
          },
        );
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(MessageSending(event.message));

    final result = await chatUseCase.sendMessage(event.message);

    result.fold(
      (failure) => emit(ChatError(failure.failureMessage)),
      (_) {
        emit(MessageSent(event.message));
        if (state is MessagesLoaded) {
          emit((state as MessagesLoaded).copyWith(clearReplyToMessage: true));
        }
      },
    );
  }

  Future<void> _onSendMediaMessage(
    SendMediaMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is MessagesLoaded) {
      emit((state as MessagesLoaded).copyWith(
        isUploading: true,
        uploadProgress: 0.0,
      ));
    }

    final uploadResult = await chatUseCase.uploadMedia(
      event.filePath,
      event.chatId,
      event.type,
      (progress) {
        if (state is MessagesLoaded) {
          emit((state as MessagesLoaded).copyWith(
            uploadProgress: progress,
            isUploading: true,
          ));
        }
      },
    );

    await uploadResult.fold(
      (failure) async {
        emit(ChatError(failure.failureMessage));
        if (state is MessagesLoaded) {
          emit((state as MessagesLoaded).copyWith(isUploading: false));
        }
      },
      (mediaUrl) async {
        final fileName = event.filePath.split('/').last;
        
        final message = Message(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          chatId: event.chatId,
          senderId: event.senderId,
          senderName: event.senderName,
          senderAvatar: event.senderAvatar,
          content: event.type == MessageType.document ? fileName : '',
          type: event.type,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          mediaUrl: mediaUrl,
          fileName: event.type == MessageType.document ? fileName : null,
          replyToMessageId: event.replyToMessageId,
        );

        add(SendMessage(message));

        if (state is MessagesLoaded) {
          emit((state as MessagesLoaded).copyWith(
            isUploading: false,
            uploadProgress: 0.0,
          ));
        }
      },
    );
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await chatUseCase.markMessageAsRead(
      event.chatId,
      event.messageId,
      event.userId,
    );
  }

  Future<void> _onSetTypingStatus(
    SetTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    await chatUseCase.setTypingStatus(
      event.chatId,
      event.userId,
      event.isTyping,
    );
  }

  Future<void> _onUpdateLastSeen(
    UpdateLastSeen event,
    Emitter<ChatState> emit,
  ) async {
    await chatUseCase.updateLastSeen(event.chatId, event.userId);
  }

  Future<void> _onSetReplyToMessage(
    SetReplyToMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is MessagesLoaded) {
      emit((state as MessagesLoaded).copyWith(
        replyToMessage: event.message,
        clearReplyToMessage: event.message == null,
      ));
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await chatUseCase.deleteMessage(event.messageId);

    result.fold(
      (failure) => emit(ChatError(failure.failureMessage)),
      (_) => null,
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _chatSubscription?.cancel();
    return super.close();
  }
}
