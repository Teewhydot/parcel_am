import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/watch_user_chats.dart';

// Events
abstract class ChatsListEvent extends Equatable {
  const ChatsListEvent();

  @override
  List<Object?> get props => [];
}

class LoadChats extends ChatsListEvent {
  final String userId;

  const LoadChats(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class ChatsListState extends Equatable {
  const ChatsListState();

  @override
  List<Object?> get props => [];
}

class ChatsListInitial extends ChatsListState {}

class ChatsListLoading extends ChatsListState {}

class ChatsListLoaded extends ChatsListState {
  final List<Chat> chats;

  const ChatsListLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

class ChatsListError extends ChatsListState {
  final String message;

  const ChatsListError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatsListBloc extends Bloc<ChatsListEvent, ChatsListState> {
  final watchUserChats = WatchUserChats();
  StreamSubscription? _chatsSubscription;

  ChatsListBloc() : super(ChatsListInitial()) {
    on<LoadChats>(_onLoadChats);
    on<_ChatsUpdated>(_onChatsUpdated);
    on<_ChatsError>(_onChatsError);
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatsListState> emit,
  ) async {
    emit(ChatsListLoading());

    await _chatsSubscription?.cancel();

    try {
      _chatsSubscription = watchUserChats(event.userId).listen(
        (chats) {
          if (!isClosed) {
            add(_ChatsUpdated(chats));
          }
        },
        onError: (error) {
          if (!isClosed) {
            add(_ChatsError(error.toString()));
          }
        },
      );
    } catch (e) {
      emit(ChatsListError(e.toString()));
    }
  }

  void _onChatsUpdated(
    _ChatsUpdated event,
    Emitter<ChatsListState> emit,
  ) {
    emit(ChatsListLoaded(event.chats));
  }

  void _onChatsError(
    _ChatsError event,
    Emitter<ChatsListState> emit,
  ) {
    emit(ChatsListError(event.message));
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}

// Internal events
class _ChatsUpdated extends ChatsListEvent {
  final List<Chat> chats;

  const _ChatsUpdated(this.chats);

  @override
  List<Object?> get props => [chats];
}

class _ChatsError extends ChatsListEvent {
  final String message;

  const _ChatsError(this.message);

  @override
  List<Object?> get props => [message];
}
