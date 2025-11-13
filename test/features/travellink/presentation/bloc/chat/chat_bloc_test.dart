import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/travellink/domain/usecases/chat/chat_usecase.dart';
import 'package:parcel_am/features/travellink/domain/entities/chat/chat_entity.dart';
import 'package:parcel_am/features/travellink/domain/failures/failures.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/chat_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/chat_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/chat_data.dart';

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

  group('ChatBloc', () {
    const testUserId = 'user123';
    final testChat = ChatEntity(
      id: 'chat1',
      participantIds: [testUserId, 'user456'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('initial state is InitialState', () {
      expect(chatBloc.state, isA<InitialState<ChatData>>());
    });

    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits [LoadedState] when ChatLoadRequested is added with successful stream',
      build: () {
        when(mockChatUseCase.watchUserChats(testUserId))
            .thenAnswer((_) => Stream.value(Right([testChat])));
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatLoadRequested(testUserId)),
      expect: () => [
        isA<LoadingState<ChatData>>(),
        isA<LoadedState<ChatData>>().having(
          (state) => state.data?.currentUserId,
          'currentUserId',
          testUserId,
        ),
        isA<LoadedState<ChatData>>().having(
          (state) => state.data?.chats.length,
          'chats length',
          1,
        ),
      ],
    );

    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits [LoadedState, AsyncErrorState] when stream emits failure',
      build: () {
        when(mockChatUseCase.watchUserChats(testUserId)).thenAnswer(
          (_) => Stream.value(
            const Left(ServerFailure(failureMessage: 'Connection error')),
          ),
        );
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatLoadRequested(testUserId)),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<LoadingState<ChatData>>(),
        isA<LoadedState<ChatData>>(),
        isA<AsyncErrorState<ChatData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          'Connection error',
        ),
      ],
    );

    blocTest<ChatBloc, BaseState<ChatData>>(
      'emits [AsyncLoadingState, LoadedState] when ChatCreateRequested succeeds',
      build: () {
        when(mockChatUseCase.createChat(['user456', testUserId]))
            .thenAnswer((_) async => Right(testChat));
        return chatBloc;
      },
      seed: () => LoadedState<ChatData>(
        data: const ChatData(currentUserId: testUserId),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const ChatCreateRequested(['user456', testUserId])),
      expect: () => [
        isA<AsyncLoadingState<ChatData>>(),
        isA<LoadedState<ChatData>>().having(
          (state) => state.data?.chats.length,
          'chats length',
          1,
        ),
        isA<AsyncLoadedState<ChatData>>(),
      ],
    );
  });
}
