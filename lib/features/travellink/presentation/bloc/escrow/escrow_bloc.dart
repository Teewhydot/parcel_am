import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import 'escrow_event.dart';
import 'escrow_state.dart';
import '../../../domain/usecases/escrow_usecase.dart';

class EscrowBloc extends BaseBloC<EscrowEvent, BaseState<EscrowData>> {
  final EscrowUseCase _escrowUseCase;
  StreamSubscription<dynamic>? _escrowStatusSubscription;

  EscrowBloc({
    required EscrowUseCase escrowUseCase,
  })  : _escrowUseCase = escrowUseCase,
        super(const InitialState<EscrowData>()) {
    on<EscrowCreateRequested>(_onCreateRequested);
    on<EscrowHoldRequested>(_onHoldRequested);
    on<EscrowReleaseRequested>(_onReleaseRequested);
    on<EscrowCancelRequested>(_onCancelRequested);
    on<EscrowWatchRequested>(_onWatchRequested);
    on<EscrowStatusUpdated>(_onStatusUpdated);
    on<EscrowLoadUserEscrows>(_onLoadUserEscrows);
  }

  Future<void> _onCreateRequested(
    EscrowCreateRequested event,
    Emitter<BaseState<EscrowData>> emit,
  ) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.createEscrow(
      parcelId: event.parcelId,
      senderId: event.senderId,
      travelerId: event.travelerId,
      amount: event.amount,
      currency: event.currency,
    );

    result.fold(
      (failure) {
        emit(AsyncErrorState<EscrowData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (escrow) {
        final updatedData = currentData.copyWith(currentEscrow: escrow);
        emit(LoadedState<EscrowData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));

        add(EscrowWatchRequested(escrow.id));
      },
    );
  }

  Future<void> _onHoldRequested(
    EscrowHoldRequested event,
    Emitter<BaseState<EscrowData>> emit,
  ) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.holdEscrow(event.escrowId);

    result.fold(
      (failure) {
        emit(AsyncErrorState<EscrowData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (escrow) {
        final updatedData = currentData.copyWith(currentEscrow: escrow);
        emit(LoadedState<EscrowData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onReleaseRequested(
    EscrowReleaseRequested event,
    Emitter<BaseState<EscrowData>> emit,
  ) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.releaseEscrow(event.escrowId);

    result.fold(
      (failure) {
        emit(AsyncErrorState<EscrowData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (escrow) {
        final updatedData = currentData.copyWith(currentEscrow: escrow);
        emit(LoadedState<EscrowData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onCancelRequested(
    EscrowCancelRequested event,
    Emitter<BaseState<EscrowData>> emit,
  ) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.cancelEscrow(
      event.escrowId,
      event.reason,
    );

    result.fold(
      (failure) {
        emit(AsyncErrorState<EscrowData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (escrow) {
        final updatedData = currentData.copyWith(currentEscrow: escrow);
        emit(LoadedState<EscrowData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onWatchRequested(
    EscrowWatchRequested event,
    Emitter<BaseState<EscrowData>> emit,
  ) async {
    await _escrowStatusSubscription?.cancel();

    _escrowStatusSubscription = _escrowUseCase
        .watchEscrowStatus(event.escrowId)
        .listen(
          (escrowEither) {
            escrowEither.fold(
              (failure) {
                add(EscrowStatusUpdated(event.escrowId));
              },
              (escrow) {
                add(EscrowStatusUpdated(escrow.id));
              },
            );
          },
          onError: (error) {
            add(EscrowStatusUpdated(event.escrowId));
          },
        );
  }

  Future<void> _onStatusUpdated(
    EscrowStatusUpdated event,
    Emitter<BaseState<EscrowData>> emit,
  ) async {
    final result = await _escrowUseCase.getEscrow(event.escrowId);

    result.fold(
      (failure) {
      },
      (escrow) {
        final currentData = state.data ?? const EscrowData();
        final updatedData = currentData.copyWith(currentEscrow: escrow);
        emit(LoadedState<EscrowData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onLoadUserEscrows(
    EscrowLoadUserEscrows event,
    Emitter<BaseState<EscrowData>> emit,
  ) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.getUserEscrows(event.userId);

    result.fold(
      (failure) {
        emit(AsyncErrorState<EscrowData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (escrows) {
        final updatedData = currentData.copyWith(userEscrows: escrows);
        emit(LoadedState<EscrowData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _escrowStatusSubscription?.cancel();
    return super.close();
  }
}
