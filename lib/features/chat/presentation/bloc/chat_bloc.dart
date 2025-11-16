import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/usecases/chat_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final chatUseCase = ChatUseCase();
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _chatSubscription;

  ChatBloc() : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<SetTypingStatus>(_onSetTypingStatus);
    on<UpdateLastSeen>(_onUpdateLastSeen);
    on<SetReplyToMessage>(_onSetReplyToMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<_MessagesUpdated>(_onMessagesUpdated);
    on<_ChatUpdated>(_onChatUpdated);
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
            if (!isClosed) {
              add(_MessagesUpdated(messages));
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
            if (!isClosed) {
              add(_ChatUpdated(chat));
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

  void _onMessagesUpdated(
    _MessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    if (state is MessagesLoaded) {
      emit((state as MessagesLoaded).copyWith(messages: event.messages));
    } else {
      emit(MessagesLoaded(messages: event.messages));
    }
  }

  void _onChatUpdated(
    _ChatUpdated event,
    Emitter<ChatState> emit,
  ) {
    if (state is MessagesLoaded) {
      emit((state as MessagesLoaded).copyWith(chat: event.chat));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _chatSubscription?.cancel();
    return super.close();
  }
}

// Internal events
class _MessagesUpdated extends ChatEvent {
  final List<Message> messages;

  const _MessagesUpdated(this.messages);

  @override
  List<Object> get props => [messages];
}

class _ChatUpdated extends ChatEvent {
  final dynamic chat;

  const _ChatUpdated(this.chat);

  @override
  List<Object?> get props => [chat];
}
