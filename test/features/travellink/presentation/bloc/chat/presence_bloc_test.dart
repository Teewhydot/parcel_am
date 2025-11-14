import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/travellink/domain/usecases/chat/presence_usecase.dart';
import 'package:parcel_am/features/travellink/domain/entities/chat/presence_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/presence_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/presence_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/presence_data.dart';

@GenerateMocks([PresenceUseCase])
import 'presence_bloc_test.mocks.dart';

void main() {
  late PresenceBloc presenceBloc;
  late MockPresenceUseCase mockPresenceUseCase;

  setUp(() {
    mockPresenceUseCase = MockPresenceUseCase();
    presenceBloc = PresenceBloc(presenceUseCase: mockPresenceUseCase);
  });

  tearDown(() {
    presenceBloc.close();
  });

  group('PresenceBloc', () {
    const testUserId = 'user123';
    const testChatId = 'chat123';
    final testPresence = PresenceEntity(
      userId: testUserId,
      status: OnlineStatus.online,
      lastSeen: DateTime.now(),
    );

    test('initial state is InitialState', () {
      expect(presenceBloc.state, isA<InitialState<PresenceData>>());
    });

    blocTest<PresenceBloc, BaseState<PresenceData>>(
      'emits [LoadedState] when PresenceLoadRequested is added with successful stream',
      build: () {
        when(mockPresenceUseCase.watchUserPresence(testUserId))
            .thenAnswer((_) => Stream.value(Right(testPresence)));
        return presenceBloc;
      },
      act: (bloc) => bloc.add(const PresenceLoadRequested(testUserId)),
      expect: () => [
        isA<LoadedState<PresenceData>>().having(
          (state) => state.data?.hasActivePresenceSubscription(testUserId),
          'hasActivePresenceSubscription',
          true,
        ),
        isA<LoadedState<PresenceData>>().having(
          (state) => state.data?.getPresence(testUserId)?.status,
          'status',
          OnlineStatus.online,
        ),
      ],
    );

    blocTest<PresenceBloc, BaseState<PresenceData>>(
      'emits [AsyncLoadingState, AsyncLoadedState] when PresenceUpdateRequested succeeds',
      build: () {
        when(mockPresenceUseCase.updatePresence(
          userId: testUserId,
          status: OnlineStatus.online,
        )).thenAnswer((_) async => const Right(null));
        return presenceBloc;
      },
      seed: () => LoadedState<PresenceData>(
        data: const PresenceData(),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const PresenceUpdateRequested(
        userId: testUserId,
        status: OnlineStatus.online,
      )),
      expect: () => [
        isA<AsyncLoadingState<PresenceData>>(),
        isA<AsyncLoadedState<PresenceData>>(),
      ],
    );

    blocTest<PresenceBloc, BaseState<PresenceData>>(
      'starts watching typing when TypingStarted is added',
      build: () {
        when(mockPresenceUseCase.watchTypingStatus(testChatId))
            .thenAnswer((_) => Stream.value(const Right({testUserId: true})));
        when(mockPresenceUseCase.setTypingStatus(
          userId: testUserId,
          chatId: testChatId,
          isTyping: true,
        )).thenAnswer((_) async => const Right(null));
        return presenceBloc;
      },
      seed: () => LoadedState<PresenceData>(
        data: const PresenceData(),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const TypingStarted(
        userId: testUserId,
        chatId: testChatId,
      )),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<LoadedState<PresenceData>>().having(
          (state) => state.data?.hasActiveTypingSubscription(testChatId),
          'hasActiveTypingSubscription',
          true,
        ),
        isA<LoadedState<PresenceData>>().having(
          (state) => state.data?.getTypingStatus(testChatId)[testUserId],
          'typing status',
          true,
        ),
      ],
    );
  });
}
