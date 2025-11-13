import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/features/chat/domain/entities/chat_entity.dart';
import 'package:parcel_am/features/chat/domain/entities/user_entity.dart';
import 'package:parcel_am/features/chat/domain/usecases/chat_usecase.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_data.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_event.dart';

@GenerateMocks([ChatUseCase])
import 'chat_bloc_test.mocks.dart';

void main() {
  late ChatBloc chatBloc;
  late MockChatUseCase mockChatUseCase;

  setUp(() {
    mockChatUseCase = MockChatUseCase();
    chatBloc = ChatBloc(chatUseCase: mockChatUseCase);
  });

  tearDown(() {
    chatBloc.close();
  });

  const testUserId = 'test-user-id';
  const testChatId = 'test-chat-id';

  final testChat = ChatEntity(
    id: testChatId,
    participantId: 'participant-id',
    participantName: 'John Doe',
    lastMessage: 'Hello!',
    lastMessageTime: DateTime.now(),
    unreadCount: 2,
    presenceStatus: PresenceStatus.online,
  );

  final testUser = ChatUserEntity(
    id: 'user-id',
    name: 'Jane Smith',
    email: 'jane@example.com',
    isOnline: true,
  );

  group('ChatLoadRequested', () {
    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits [LoadingState, LoadedState] when chat list loads successfully',
      build: () {
        when(mockChatUseCase.getChatList(testUserId)).thenAnswer(
          (_) => Stream.value(Right([testChat])),
        );
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatLoadRequested(testUserId)),
      expect: () => [
        const LoadingState<ChatData>(message: 'Loading chats...'),
        isA<LoadedState<ChatData>>()
            .having((s) => s.data?.chats.length, 'chats length', 1)
            .having((s) => s.data?.chats.first.id, 'first chat id', testChatId),
      ],
    );

    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits [LoadingState, ErrorState] when chat list fails to load',
      build: () {
        when(mockChatUseCase.getChatList(testUserId)).thenAnswer(
          (_) => Stream.value(
              const Left(ServerFailure(failureMessage: 'Failed to load'))),
        );
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatLoadRequested(testUserId)),
      expect: () => [
        const LoadingState<ChatData>(message: 'Loading chats...'),
        const ErrorState<ChatData>(
          errorMessage: 'Failed to load',
          errorCode: 'chat_load_failed',
        ),
      ],
    );
  });

  group('ChatDeleteRequested', () {
    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits SuccessState when chat is deleted successfully',
      build: () {
        when(mockChatUseCase.deleteChat(testChatId))
            .thenAnswer((_) async => const Right(null));
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatDeleteRequested(testChatId)),
      expect: () => [
        const SuccessState<ChatData>(successMessage: 'Chat deleted successfully'),
      ],
    );

    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits ErrorState when chat deletion fails',
      build: () {
        when(mockChatUseCase.deleteChat(testChatId)).thenAnswer(
          (_) async =>
              const Left(ServerFailure(failureMessage: 'Delete failed')),
        );
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatDeleteRequested(testChatId)),
      expect: () => [
        const ErrorState<ChatData>(
          errorMessage: 'Delete failed',
          errorCode: 'chat_delete_failed',
        ),
      ],
    );
  });

  group('ChatSearchUsersRequested', () {
    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits [LoadingState, LoadedState] when users are found',
      build: () {
        when(mockChatUseCase.searchUsers('Jane')).thenAnswer(
          (_) async => Right([testUser]),
        );
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatSearchUsersRequested('Jane')),
      expect: () => [
        const LoadingState<ChatData>(message: 'Searching users...'),
        isA<LoadedState<ChatData>>()
            .having((s) => s.data?.searchResults.length, 'search results length', 1)
            .having((s) => s.data?.searchResults.first.name, 'first user name', 'Jane Smith'),
      ],
    );

    blocTest<ChatBloc, BaseState<ChatData>>(
      'clears search results when query is empty',
      build: () => chatBloc,
      act: (bloc) => bloc.add(const ChatSearchUsersRequested('')),
      expect: () => [
        isA<LoadedState<ChatData>>()
            .having((s) => s.data?.searchResults, 'empty search results', []),
      ],
    );
  });

  group('ChatCreateRequested', () {
    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits [LoadingState, SuccessState] when chat is created successfully',
      build: () {
        when(mockChatUseCase.createChat(testUserId, 'participant-id'))
            .thenAnswer((_) async => const Right('new-chat-id'));
        return chatBloc;
      },
      act: (bloc) =>
          bloc.add(const ChatCreateRequested(testUserId, 'participant-id')),
      expect: () => [
        const LoadingState<ChatData>(message: 'Creating chat...'),
        const SuccessState<ChatData>(
          successMessage: 'Chat created successfully',
          metadata: {'chatId': 'new-chat-id'},
        ),
      ],
    );
  });

  group('ChatFilterChanged', () {
    blocTest<ChatBloc, BaseState<ChatData>>(
      'updates filter in loaded state',
      build: () => chatBloc,
      seed: () => LoadedState<ChatData>(
        data: const ChatData(chats: []),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const ChatFilterChanged('test filter')),
      expect: () => [
        isA<LoadedState<ChatData>>()
            .having((s) => s.data?.filter, 'filter', 'test filter'),
      ],
    );
  });
}
