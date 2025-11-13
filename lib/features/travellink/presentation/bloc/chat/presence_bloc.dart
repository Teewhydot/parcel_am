import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_bloc.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import '../../../domain/usecases/chat/presence_usecase.dart';
import '../../../domain/entities/chat/presence_entity.dart';
import 'presence_event.dart';
import 'presence_data.dart';

class PresenceBloc extends BaseBloC<PresenceEvent, BaseState<PresenceData>> {
  final PresenceUseCase _presenceUseCase;
  final Map<String, StreamSubscription> _presenceSubscriptions = {};
  final Map<String, StreamSubscription> _typingSubscriptions = {};

  PresenceBloc({PresenceUseCase? presenceUseCase})
      : _presenceUseCase = presenceUseCase ?? PresenceUseCase(),
        super(const InitialState<PresenceData>()) {
    on<PresenceLoadRequested>(_onPresenceLoadRequested);
    on<PresenceUpdateRequested>(_onPresenceUpdateRequested);
    on<TypingStarted>(_onTypingStarted);
    on<TypingEnded>(_onTypingEnded);
    on<PresenceUpdated>(_onPresenceUpdated);
    on<TypingStatusUpdated>(_onTypingStatusUpdated);
    on<PresenceStreamError>(_onPresenceStreamError);
    on<PresenceUnsubscribeRequested>(_onPresenceUnsubscribeRequested);
    on<TypingUnsubscribeRequested>(_onTypingUnsubscribeRequested);
  }

  Future<void> _onPresenceLoadRequested(
    PresenceLoadRequested event,
    Emitter<BaseState<PresenceData>> emit,
  ) async {
    final currentData = _getCurrentData();

    // Cancel existing subscription for this user if any
    await _presenceSubscriptions[event.userId]?.cancel();

    // Start listening to presence
    _presenceSubscriptions[event.userId] =
        _presenceUseCase.watchUserPresence(event.userId).listen(
      (either) {
        either.fold(
          (failure) {
            add(PresenceStreamError(event.userId, failure.failureMessage));
          },
          (presence) {
            add(PresenceUpdated(event.userId, presence));
          },
        );
      },
      onError: (error) {
        add(PresenceStreamError(event.userId, error.toString()));
      },
    );

    emit(LoadedState<PresenceData>(
      data: currentData.addPresenceSubscription(event.userId),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onPresenceUpdateRequested(
    PresenceUpdateRequested event,
    Emitter<BaseState<PresenceData>> emit,
  ) async {
    final currentData = _getCurrentData();
    emit(AsyncLoadingState<PresenceData>(data: currentData));

    final result = await _presenceUseCase.updatePresence(
      userId: event.userId,
      status: event.status,
      currentChatId: event.currentChatId,
    );

    result.fold(
      (failure) {
        emit(AsyncErrorState<PresenceData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (_) {
        emit(AsyncLoadedState<PresenceData>(
          data: currentData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onTypingStarted(
    TypingStarted event,
    Emitter<BaseState<PresenceData>> emit,
  ) async {
    final currentData = _getCurrentData();

    // Subscribe to typing status if not already
    if (!currentData.hasActiveTypingSubscription(event.chatId)) {
      _typingSubscriptions[event.chatId] =
          _presenceUseCase.watchTypingStatus(event.chatId).listen(
        (either) {
          either.fold(
            (failure) {
              // Handle error silently
            },
            (typingUsers) {
              add(TypingStatusUpdated(event.chatId, typingUsers));
            },
          );
        },
      );

      emit(LoadedState<PresenceData>(
        data: currentData.addTypingSubscription(event.chatId),
        lastUpdated: DateTime.now(),
      ));
    }

    // Set typing status
    await _presenceUseCase.setTypingStatus(
      userId: event.userId,
      chatId: event.chatId,
      isTyping: true,
    );
  }

  Future<void> _onTypingEnded(
    TypingEnded event,
    Emitter<BaseState<PresenceData>> emit,
  ) async {
    await _presenceUseCase.setTypingStatus(
      userId: event.userId,
      chatId: event.chatId,
      isTyping: false,
    );
  }

  void _onPresenceUpdated(
    PresenceUpdated event,
    Emitter<BaseState<PresenceData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(LoadedState<PresenceData>(
      data: currentData.updatePresence(event.userId, event.presence),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onTypingStatusUpdated(
    TypingStatusUpdated event,
    Emitter<BaseState<PresenceData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(LoadedState<PresenceData>(
      data: currentData.updateTypingStatus(event.chatId, event.typingUsers),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onPresenceStreamError(
    PresenceStreamError event,
    Emitter<BaseState<PresenceData>> emit,
  ) {
    final currentData = _getCurrentData();
    emit(AsyncErrorState<PresenceData>(
      errorMessage: event.error,
      data: currentData,
    ));
  }

  Future<void> _onPresenceUnsubscribeRequested(
    PresenceUnsubscribeRequested event,
    Emitter<BaseState<PresenceData>> emit,
  ) async {
    await _presenceSubscriptions[event.userId]?.cancel();
    _presenceSubscriptions.remove(event.userId);

    final currentData = _getCurrentData();
    emit(LoadedState<PresenceData>(
      data: currentData.removePresenceSubscription(event.userId),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onTypingUnsubscribeRequested(
    TypingUnsubscribeRequested event,
    Emitter<BaseState<PresenceData>> emit,
  ) async {
    await _typingSubscriptions[event.chatId]?.cancel();
    _typingSubscriptions.remove(event.chatId);

    final currentData = _getCurrentData();
    emit(LoadedState<PresenceData>(
      data: currentData.removeTypingSubscription(event.chatId),
      lastUpdated: DateTime.now(),
    ));
  }

  PresenceData _getCurrentData() {
    if (state is DataState<PresenceData> && state.data != null) {
      return state.data!;
    }
    return const PresenceData();
  }

  @override
  Future<void> close() {
    for (var subscription in _presenceSubscriptions.values) {
      subscription.cancel();
    }
    _presenceSubscriptions.clear();

    for (var subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    _typingSubscriptions.clear();

    return super.close();
  }
}
