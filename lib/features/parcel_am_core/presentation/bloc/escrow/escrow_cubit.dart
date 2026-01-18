import 'package:dartz/dartz.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/errors/failures.dart';
import 'escrow_state.dart';
import '../../../domain/entities/escrow_entity.dart';
import '../../../domain/usecases/escrow_usecase.dart';

class EscrowCubit extends BaseCubit<BaseState<EscrowData>> {
  final _escrowUseCase = EscrowUseCase();

  EscrowCubit() : super(const InitialState<EscrowData>());

  /// Stream for watching escrow status - use with StreamBuilder
  Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(String escrowId) async* {
    try {
      yield* _escrowUseCase.watchEscrowStatus(escrowId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  Future<void> createEscrow({
    required String parcelId,
    required String senderId,
    required String travelerId,
    required double amount,
    required String currency,
  }) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.createEscrow(
      parcelId: parcelId,
      senderId: senderId,
      travelerId: travelerId,
      amount: amount,
      currency: currency,
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

  Future<void> holdEscrow(String escrowId) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.holdEscrow(escrowId);

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

  Future<void> releaseEscrow(String escrowId) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.releaseEscrow(escrowId);

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

  Future<void> cancelEscrow(String escrowId, String reason) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.cancelEscrow(escrowId, reason);

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

  Future<void> loadUserEscrows(String userId) async {
    final currentData = state.data ?? const EscrowData();
    emit(AsyncLoadingState<EscrowData>(data: currentData));

    final result = await _escrowUseCase.getUserEscrows(userId);

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

  Future<void> getEscrow(String escrowId) async {
    final result = await _escrowUseCase.getEscrow(escrowId);

    result.fold(
      (failure) {},
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
}
