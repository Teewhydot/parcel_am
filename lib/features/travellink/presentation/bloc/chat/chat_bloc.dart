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
