import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import '../../../domain/usecases/chat/message_usecase.dart';
import 'message_event.dart';
import 'message_data.dart';

class MessageBloc extends BaseBloC<MessageEvent, BaseState<MessageData>> {
  final MessageUseCase _messageUseCase;
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  MessageBloc({MessageUseCase? messageUseCase})
      : _messageUseCase = messageUseCase ?? MessageUseCase(),
        super(const InitialState<MessageData>()) {
    on<MessageLoadRequested>(_onMessageLoadRequested);
    on<MessageSendRequested>(_onMessageSendRequested);
    on<MessageDeleteRequested>(_onMessageDeleteRequested);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<MessageStreamError>(_onMessageStreamError);
    on<MessageUnsubscribeRequested>(_onMessageUnsubscribeRequested);
  }

  Future<void> _onMessageLoadRequested(
    MessageLoadRequested event,
    Emitter<BaseState<MessageData>> emit,
  ) async {
    final currentData = _getCurrentData();

    // Cancel existing subscription for this chat if any
    await _messageSubscriptions[event.chatId]?.cancel();

    // Start listening to messages
    _messageSubscriptions[event.chatId] =
        _messageUseCase.watchMessages(event.chatId).listen(
      (either) {
        either.fold(
          (failure) {
            add(MessageStreamError(event.chatId, failure.failureMessage));
          },
          (messages) {
            add(MessagesUpdated(event.chatId, messages));
          },
        );
      },
      onError: (error) {
        add(MessageStreamError(event.chatId, error.toString()));
      },
    );

    emit(LoadedState<MessageData>(
      data: currentData.addSubscription(event.chatId),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onMessageSendRequested(
    MessageSendRequested event,
    Emitter<BaseState<MessageData>> emit,
  ) async {
    final currentData = _getCurrentData();
    emit(AsyncLoadingState<MessageData>(data: currentData));

    final result = await _messageUseCase.sendMessage(
      chatId: event.chatId,
      senderId: event.senderId,
      content: event.content,
      type: event.type,
      replyToId: event.replyToId,
    );

    result.fold(
      (failure) {
        emit(AsyncErrorState<MessageData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (message) {
        emit(AsyncLoadedState<MessageData>(
          data: currentData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onMessageDeleteRequested(
    MessageDeleteRequested event,
    Emitter<BaseState<MessageData>> emit,
  ) async {
    final currentData = _getCurrentData();
    emit(AsyncLoadingState<MessageData>(data: currentData));

    final result = await _messageUseCase.deleteMessage(event.messageId);

    result.fold(
      (failure) {
        emit(AsyncErrorState<MessageData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (_) {
        emit(AsyncLoadedState<MessageData>(
          data: currentData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  void _onMessagesUpdated(
    MessagesUpdated event,
    Emitter<BaseState<MessageData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(LoadedState<MessageData>(
      data: currentData.updateMessages(event.chatId, event.messages),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onMessageStreamError(
    MessageStreamError event,
    Emitter<BaseState<MessageData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(AsyncErrorState<MessageData>(
      errorMessage: event.error,
      data: currentData,
    ));
  }

  Future<void> _onMessageUnsubscribeRequested(
    MessageUnsubscribeRequested event,
    Emitter<BaseState<MessageData>> emit,
  ) async {
    await _messageSubscriptions[event.chatId]?.cancel();
    _messageSubscriptions.remove(event.chatId);

    final currentData = _getCurrentData();
    emit(LoadedState<MessageData>(
      data: currentData.removeSubscription(event.chatId),
      lastUpdated: DateTime.now(),
    ));
  }

  MessageData _getCurrentData() {
    if (state is DataState<MessageData> && state.data != null) {
      return state.data!;
    }
    return const MessageData();
  }

  @override
  Future<void> close() {
    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    return super.close();
  }
}
