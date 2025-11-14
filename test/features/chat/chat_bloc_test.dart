import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/features/chat/domain/entities/message.dart';
import 'package:parcel_am/features/chat/domain/entities/message_type.dart';
import 'package:parcel_am/features/chat/domain/usecases/chat_usecase.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_event.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_state.dart';

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
    final testMessage = Message(
      id: '1',
      chatId: 'chat_123',
      senderId: 'user_1',
      senderName: 'John Doe',
      content: 'Hello World',
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    test('initial state is ChatInitial', () {
      expect(chatBloc.state, equals(ChatInitial()));
    });

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, MessagesLoaded] when LoadMessages is successful',
      build: () {
        when(mockChatUseCase.getMessagesStream(any))
            .thenAnswer((_) => Stream.value(Right([testMessage])));
        return chatBloc;
      },
      act: (bloc) => bloc.add(const LoadMessages('chat_123')),
      expect: () => [
        ChatLoading(),
        MessagesLoaded(messages: [testMessage]),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [MessageSending, MessageSent] when SendMessage is successful',
      build: () {
        when(mockChatUseCase.sendMessage(any))
            .thenAnswer((_) async => const Right(null));
        return chatBloc;
      },
      act: (bloc) => bloc.add(SendMessage(testMessage)),
      expect: () => [
        MessageSending(testMessage),
        MessageSent(testMessage),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [MessageSending, ChatError] when SendMessage fails',
      build: () {
        when(mockChatUseCase.sendMessage(any))
            .thenAnswer((_) async => const Left(
                  ServerFailure(failureMessage: 'Failed to send message'),
                ));
        return chatBloc;
      },
      act: (bloc) => bloc.add(SendMessage(testMessage)),
      expect: () => [
        MessageSending(testMessage),
        const ChatError('Failed to send message'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'updates replyToMessage when SetReplyToMessage is called',
      build: () => chatBloc,
      seed: () => MessagesLoaded(messages: const []),
      act: (bloc) => bloc.add(SetReplyToMessage(testMessage)),
      expect: () => [
        MessagesLoaded(messages: const [], replyToMessage: testMessage),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'clears replyToMessage when SetReplyToMessage(null) is called',
      build: () => chatBloc,
      seed: () => MessagesLoaded(messages: const [], replyToMessage: testMessage),
      act: (bloc) => bloc.add(const SetReplyToMessage(null)),
      expect: () => [
        const MessagesLoaded(messages: [], replyToMessage: null),
      ],
    );
  });
}
