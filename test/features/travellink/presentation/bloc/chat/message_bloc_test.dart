import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/travellink/domain/usecases/chat/message_usecase.dart';
import 'package:parcel_am/features/travellink/domain/entities/chat/message_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/message_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/message_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/message_data.dart';

@GenerateMocks([MessageUseCase])
import 'message_bloc_test.mocks.dart';

void main() {
  late MessageBloc messageBloc;
  late MockMessageUseCase mockMessageUseCase;

  setUp(() {
    mockMessageUseCase = MockMessageUseCase();
    messageBloc = MessageBloc(messageUseCase: mockMessageUseCase);
  });

  tearDown(() {
    messageBloc.close();
  });

  group('MessageBloc', () {
    const testChatId = 'chat123';
    const testUserId = 'user123';
    final testMessage = MessageEntity(
      id: 'msg1',
      chatId: testChatId,
      senderId: testUserId,
      content: 'Hello',
      timestamp: DateTime.now(),
    );

    test('initial state is InitialState', () {
      expect(messageBloc.state, isA<InitialState<MessageData>>());
    });

    blocTest<MessageBloc, BaseState<MessageData>>(
      'emits [LoadedState] when MessageLoadRequested is added with successful stream',
      build: () {
        when(mockMessageUseCase.watchMessages(testChatId))
            .thenAnswer((_) => Stream.value(Right([testMessage])));
        return messageBloc;
      },
      act: (bloc) => bloc.add(const MessageLoadRequested(testChatId)),
      expect: () => [
        isA<LoadedState<MessageData>>().having(
          (state) => state.data?.hasActiveSubscription(testChatId),
          'hasActiveSubscription',
          true,
        ),
        isA<LoadedState<MessageData>>().having(
          (state) => state.data?.getMessages(testChatId).length,
          'messages length',
          1,
        ),
      ],
    );

    blocTest<MessageBloc, BaseState<MessageData>>(
      'emits [AsyncLoadingState, AsyncLoadedState] when MessageSendRequested succeeds',
      build: () {
        when(mockMessageUseCase.sendMessage(
          chatId: testChatId,
          senderId: testUserId,
          content: 'Hello',
          type: MessageType.text,
        )).thenAnswer((_) async => Right(testMessage));
        return messageBloc;
      },
      seed: () => LoadedState<MessageData>(
        data: const MessageData(),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const MessageSendRequested(
        chatId: testChatId,
        senderId: testUserId,
        content: 'Hello',
      )),
      expect: () => [
        isA<AsyncLoadingState<MessageData>>(),
        isA<AsyncLoadedState<MessageData>>(),
      ],
    );

    blocTest<MessageBloc, BaseState<MessageData>>(
      'emits [AsyncLoadingState, AsyncLoadedState] when MessageDeleteRequested succeeds',
      build: () {
        when(mockMessageUseCase.deleteMessage('msg1'))
            .thenAnswer((_) async => const Right(null));
        return messageBloc;
      },
      seed: () => LoadedState<MessageData>(
        data: const MessageData(),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const MessageDeleteRequested('msg1')),
      expect: () => [
        isA<AsyncLoadingState<MessageData>>(),
        isA<AsyncLoadedState<MessageData>>(),
      ],
    );
  });
}
