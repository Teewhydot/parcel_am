import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/bloc/base/base_state.dart';
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

// BLoC
class ChatsListBloc extends Bloc<ChatsListEvent, BaseState<List<Chat>>> {
  final watchUserChats = WatchUserChats();

  ChatsListBloc() : super(const InitialState<List<Chat>>()) {
    on<LoadChats>(_onLoadChats);
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<BaseState<List<Chat>>> emit,
  ) async {
    emit(const LoadingState<List<Chat>>());

    await emit.forEach<List<Chat>>(
      watchUserChats(event.userId),
      onData: (chats) => LoadedState<List<Chat>>(data: chats),
      onError: (error, stackTrace) => ErrorState<List<Chat>>(
        errorMessage: error.toString(),
      ),
    );
  }
}
