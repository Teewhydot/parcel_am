// Mocks generated manually for profile_screen_test.dart

import 'package:mockito/mockito.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  BaseState<AuthData> get state => super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: const InitialState<AuthData>(),
        returnValueForMissingStub: const InitialState<AuthData>(),
      );

  @override
  Stream<BaseState<AuthData>> get stream => super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: Stream<BaseState<AuthData>>.empty(),
        returnValueForMissingStub: Stream<BaseState<AuthData>>.empty(),
      );

  @override
  void add(AuthEvent event) => super.noSuchMethod(
        Invocation.method(#add, [event]),
        returnValueForMissingStub: null,
      );

  @override
  Future<void> close() => super.noSuchMethod(
        Invocation.method(#close, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}
