import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import '../../../domain/usecases/chat/chat_usecase.dart';
import 'chat_event.dart';
import 'chat_data.dart';

class ChatBloc extends BaseBloC<ChatEvent, BaseState<ChatData>> {
  final ChatUseCase _chatUseCase;
  StreamSubscription? _chatsSubscription;

  ChatBloc({ChatUseCase? chatUseCase})
      : _chatUseCase = chatUseCase ?? ChatUseCase(),
        super(const InitialState<ChatData>()) {
    on<ChatLoadRequested>(_onChatLoadRequested);
    on<ChatCreateRequested>(_onChatCreateRequested);
    on<ChatUpdated>(_onChatUpdated);
    on<ChatMarkAsRead>(_onChatMarkAsRead);
    on<ChatStreamError>(_onChatStreamError);
    on<ChatFilterChanged>(_onChatFilterChanged);
    on<ChatTogglePinRequested>(_onChatTogglePinRequested);
    on<ChatToggleMuteRequested>(_onChatToggleMuteRequested);
    on<ChatMarkAsReadRequested>(_onChatMarkAsReadRequested);
    on<ChatDeleteRequested>(_onChatDeleteRequested);
  }

  Future<void> _onChatLoadRequested(
    ChatLoadRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    emit(const LoadingState<ChatData>());

    await _chatsSubscription?.cancel();

    _chatsSubscription = _chatUseCase.watchUserChats(event.userId).listen(
      (either) {
        either.fold(
          (failure) {
            add(ChatStreamError(failure.failureMessage));
          },
          (chats) {
            add(ChatUpdated(chats));
          },
        );
      },
      onError: (error) {
        add(ChatStreamError(error.toString()));
      },
    );

    emit(LoadedState<ChatData>(
      data: ChatData(
        currentUserId: event.userId,
        isListening: true,
      ),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onChatCreateRequested(
    ChatCreateRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final currentData = _getCurrentData();
    emit(AsyncLoadingState<ChatData>(data: currentData));

    final result = await _chatUseCase.createChat(event.participantIds);

    result.fold(
      (failure) {
        emit(AsyncErrorState<ChatData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (chat) {
        final updatedChats = [chat, ...currentData.chats];
        emit(LoadedState<ChatData>(
          data: currentData.copyWith(chats: updatedChats),
          lastUpdated: DateTime.now(),
        ));
        emit(AsyncLoadedState<ChatData>(
          data: currentData.copyWith(chats: updatedChats),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  void _onChatUpdated(
    ChatUpdated event,
    Emitter<BaseState<ChatData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(LoadedState<ChatData>(
      data: currentData.copyWith(chats: event.chats),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onChatMarkAsRead(
    ChatMarkAsRead event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final result = await _chatUseCase.markAsRead(event.chatId, event.userId);

    result.fold(
      (failure) {
        // Silently fail or show a snackbar
      },
      (_) {
        // Mark as read success
      },
    );
  }

  void _onChatStreamError(
    ChatStreamError event,
    Emitter<BaseState<ChatData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(AsyncErrorState<ChatData>(
      errorMessage: event.error,
      data: currentData,
    ));
  }

  void _onChatFilterChanged(
    ChatFilterChanged event,
    Emitter<BaseState<ChatData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(LoadedState<ChatData>(
      data: currentData.copyWith(filter: event.filter),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onChatTogglePinRequested(
    ChatTogglePinRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final currentData = _getCurrentData();

    // Find the chat and toggle pin status
    final updatedChats = currentData.chats.map((chat) {
      if (chat.id == event.chatId) {
        final newMetadata = Map<String, dynamic>.from(chat.metadata);
        newMetadata['isPinned'] = !(chat.metadata['isPinned'] as bool? ?? false);
        return chat.copyWith(metadata: newMetadata);
      }
      return chat;
    }).toList();

    emit(LoadedState<ChatData>(
      data: currentData.copyWith(chats: updatedChats),
      lastUpdated: DateTime.now(),
    ));

    // TODO: Persist to Firestore via repository
  }

  Future<void> _onChatToggleMuteRequested(
    ChatToggleMuteRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final currentData = _getCurrentData();

    // Find the chat and toggle mute status
    final updatedChats = currentData.chats.map((chat) {
      if (chat.id == event.chatId) {
        final newMetadata = Map<String, dynamic>.from(chat.metadata);
        newMetadata['isMuted'] = !(chat.metadata['isMuted'] as bool? ?? false);
        return chat.copyWith(metadata: newMetadata);
      }
      return chat;
    }).toList();

    emit(LoadedState<ChatData>(
      data: currentData.copyWith(chats: updatedChats),
      lastUpdated: DateTime.now(),
    ));

    // TODO: Persist to Firestore via repository
  }

  Future<void> _onChatMarkAsReadRequested(
    ChatMarkAsReadRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final currentData = _getCurrentData();
    final userId = currentData.currentUserId;

    if (userId != null) {
      await _onChatMarkAsRead(
        ChatMarkAsRead(event.chatId, userId),
        emit,
      );
    }
  }

  Future<void> _onChatDeleteRequested(
    ChatDeleteRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final currentData = _getCurrentData();

    // Remove the chat from the list
    final updatedChats = currentData.chats
        .where((chat) => chat.id != event.chatId)
        .toList();

    emit(LoadedState<ChatData>(
      data: currentData.copyWith(chats: updatedChats),
      lastUpdated: DateTime.now(),
    ));

    // TODO: Delete from Firestore via repository
  }

  ChatData _getCurrentData() {
    if (state is DataState<ChatData> && state.data != null) {
      return state.data!;
    }
    return const ChatData();
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}
