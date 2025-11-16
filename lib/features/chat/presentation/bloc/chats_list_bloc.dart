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

  ChatsListBloc() : super(ChatsListInitial()) {
    on<LoadChats>(_onLoadChats);
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatsListState> emit,
  ) async {
    emit(ChatsListLoading());

    await emit.forEach<List<Chat>>(
      watchUserChats(event.userId),
      onData: (chats) => ChatsListLoaded(chats),
      onError: (error, stackTrace) => ChatsListError(error.toString()),
    );
  }
}
