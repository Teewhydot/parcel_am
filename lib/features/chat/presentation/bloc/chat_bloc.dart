import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../domain/usecases/chat_usecase.dart';
import 'chat_event.dart';
import 'chat_data.dart';

class ChatBloc extends BaseBloC<ChatEvent, BaseState<ChatData>> {
  final ChatUseCase chatUseCase;
  StreamSubscription? _chatSubscription;

  ChatBloc({required this.chatUseCase}) : super(const InitialState<ChatData>()) {
    on<ChatLoadRequested>(_onChatLoadRequested);
    on<ChatDeleteRequested>(_onChatDeleteRequested);
    on<ChatMarkAsReadRequested>(_onChatMarkAsReadRequested);
    on<ChatTogglePinRequested>(_onChatTogglePinRequested);
    on<ChatToggleMuteRequested>(_onChatToggleMuteRequested);
    on<ChatSearchUsersRequested>(_onChatSearchUsersRequested);
    on<ChatCreateRequested>(_onChatCreateRequested);
    on<ChatFilterChanged>(_onChatFilterChanged);
  }

  Future<void> _onChatLoadRequested(
    ChatLoadRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    emit(const LoadingState<ChatData>(message: 'Loading chats...'));

    await _chatSubscription?.cancel();

    _chatSubscription = chatUseCase.getChatList(event.userId).listen(
      (either) {
        either.fold(
          (failure) {
            if (!isClosed) {
              emit(ErrorState<ChatData>(
                errorMessage: failure.failureMessage,
                errorCode: 'chat_load_failed',
              ));
            }
          },
          (chats) {
            if (!isClosed) {
              final currentData = _getCurrentChatData();
              emit(LoadedState<ChatData>(
                data: currentData.copyWith(
                  chats: chats,
                  currentUserId: event.userId,
                ),
                lastUpdated: DateTime.now(),
              ));
            }
          },
        );
      },
      onError: (error) {
        if (!isClosed) {
          emit(ErrorState<ChatData>(
            errorMessage: error.toString(),
            errorCode: 'chat_stream_error',
          ));
        }
      },
    );
  }

  Future<void> _onChatDeleteRequested(
    ChatDeleteRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final result = await chatUseCase.deleteChat(event.chatId);

    result.fold(
      (failure) {
        emit(ErrorState<ChatData>(
          errorMessage: failure.failureMessage,
          errorCode: 'chat_delete_failed',
        ));
      },
      (_) {
        emit(const SuccessState<ChatData>(
          successMessage: 'Chat deleted successfully',
        ));
      },
    );
  }

  Future<void> _onChatMarkAsReadRequested(
    ChatMarkAsReadRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    await chatUseCase.markAsRead(event.chatId);
  }

  Future<void> _onChatTogglePinRequested(
    ChatTogglePinRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final result = await chatUseCase.togglePin(event.chatId, event.isPinned);

    result.fold(
      (failure) {
        emit(ErrorState<ChatData>(
          errorMessage: failure.failureMessage,
          errorCode: 'chat_pin_failed',
        ));
      },
      (_) {},
    );
  }

  Future<void> _onChatToggleMuteRequested(
    ChatToggleMuteRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final result = await chatUseCase.toggleMute(event.chatId, event.isMuted);

    result.fold(
      (failure) {
        emit(ErrorState<ChatData>(
          errorMessage: failure.failureMessage,
          errorCode: 'chat_mute_failed',
        ));
      },
      (_) {},
    );
  }

  Future<void> _onChatSearchUsersRequested(
    ChatSearchUsersRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    if (event.query.isEmpty) {
      final currentData = _getCurrentChatData();
      emit(LoadedState<ChatData>(
        data: currentData.copyWith(searchResults: []),
        lastUpdated: DateTime.now(),
      ));
      return;
    }

    emit(const LoadingState<ChatData>(message: 'Searching users...'));

    final result = await chatUseCase.searchUsers(event.query);

    result.fold(
      (failure) {
        emit(ErrorState<ChatData>(
          errorMessage: failure.failureMessage,
          errorCode: 'user_search_failed',
        ));
      },
      (users) {
        final currentData = _getCurrentChatData();
        emit(LoadedState<ChatData>(
          data: currentData.copyWith(searchResults: users),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onChatCreateRequested(
    ChatCreateRequested event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    emit(const LoadingState<ChatData>(message: 'Creating chat...'));

    final result = await chatUseCase.createChat(
      event.currentUserId,
      event.participantId,
    );

    result.fold(
      (failure) {
        emit(ErrorState<ChatData>(
          errorMessage: failure.failureMessage,
          errorCode: 'chat_create_failed',
        ));
      },
      (chatId) {
        emit(SuccessState<ChatData>(
          successMessage: 'Chat created successfully',
          metadata: {'chatId': chatId},
        ));
      },
    );
  }

  Future<void> _onChatFilterChanged(
    ChatFilterChanged event,
    Emitter<BaseState<ChatData>> emit,
  ) async {
    final currentData = _getCurrentChatData();
    emit(LoadedState<ChatData>(
      data: currentData.copyWith(filter: event.filter),
      lastUpdated: DateTime.now(),
    ));
  }

  ChatData _getCurrentChatData() {
    if (state is DataState<ChatData> && (state as DataState<ChatData>).data != null) {
      return (state as DataState<ChatData>).data!;
    }
    return const ChatData();
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
