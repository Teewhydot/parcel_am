import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import 'parcel_event.dart';
import 'parcel_state.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../../domain/usecases/parcel_usecase.dart';

class ParcelBloc extends BaseBloC<ParcelEvent, BaseState<ParcelData>> {
  final _parcelUseCase = ParcelUseCase();
  StreamSubscription<dynamic>? _parcelStatusSubscription;
  StreamSubscription<dynamic>? _userParcelsSubscription;
  StreamSubscription<dynamic>? _availableParcelsSubscription;

  ParcelBloc()
      : super(const InitialState<ParcelData>()) {
    on<ParcelCreateRequested>(_onCreateRequested);
    on<ParcelUpdateStatusRequested>(_onUpdateStatusRequested);
    on<ParcelWatchRequested>(_onWatchRequested);
    on<ParcelWatchUserParcelsRequested>(_onWatchUserParcelsRequested);
    on<ParcelStatusUpdated>(_onStatusUpdated);
    on<ParcelListUpdated>(_onListUpdated);
    on<ParcelLoadRequested>(_onLoadRequested);
    on<ParcelLoadUserParcels>(_onLoadUserParcels);
    on<ParcelWatchAvailableParcelsRequested>(_onWatchAvailableParcelsRequested);
    on<ParcelAvailableListUpdated>(_onAvailableListUpdated);
    on<ParcelAssignTravelerRequested>(_onAssignTravelerRequested);
  }

  Future<void> _onCreateRequested(
    ParcelCreateRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.createParcel(event.parcel);

    result.fold(
      (failure) {
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));

        add(ParcelWatchRequested(parcel.id));
      },
    );
  }

  Future<void> _onUpdateStatusRequested(
    ParcelUpdateStatusRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.updateParcelStatus(
      event.parcelId,
      event.status,
    );

    result.fold(
      (failure) {
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onWatchRequested(
    ParcelWatchRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    await _parcelStatusSubscription?.cancel();

    _parcelStatusSubscription = _parcelUseCase
        .watchParcelStatus(event.parcelId)
        .listen(
          (parcelEither) {
            parcelEither.fold(
              (failure) {
              },
              (parcel) {
                add(ParcelStatusUpdated(parcel));
              },
            );
          },
          onError: (error) {
          },
        );
  }

  Future<void> _onWatchUserParcelsRequested(
    ParcelWatchUserParcelsRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    await _userParcelsSubscription?.cancel();

    _userParcelsSubscription = _parcelUseCase
        .watchUserParcels(event.userId)
        .listen(
          (parcelsEither) {
            parcelsEither.fold(
              (failure) {
              },
              (parcels) {
                add(ParcelListUpdated(parcels));
              },
            );
          },
          onError: (error) {
          },
        );
  }

  Future<void> _onStatusUpdated(
    ParcelStatusUpdated event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    final updatedData = currentData.copyWith(currentParcel: event.parcel);
    emit(LoadedState<ParcelData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onListUpdated(
    ParcelListUpdated event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    final updatedData = currentData.copyWith(userParcels: event.parcels);
    emit(LoadedState<ParcelData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onLoadRequested(
    ParcelLoadRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();

    // Check if we already have this parcel in availableParcels (from browse screen)
    final existingParcel = currentData.availableParcels
        .where((p) => p.id == event.parcelId)
        .firstOrNull;

    // If we already have the parcel data, show it immediately (no loading!)
    if (existingParcel != null) {
      final updatedData = currentData.copyWith(currentParcel: existingParcel);
      emit(LoadedState<ParcelData>(
        data: updatedData,
        lastUpdated: DateTime.now(),
      ));
    } else if (currentData.currentParcel?.id != event.parcelId) {
      // Only show loading if we don't have this parcel at all
      emit(const LoadingState<ParcelData>());
    }

    // Use emit.forEach for automatic stream handling (like ChatsListBloc)
    await emit.forEach<ParcelEntity>(
      _parcelUseCase.watchParcelStatus(event.parcelId).asyncMap((parcelEither) async {
        return parcelEither.fold(
          (failure) => throw Exception(failure.failureMessage),
          (parcel) => parcel,
        );
      }),
      onData: (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        return LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        );
      },
      onError: (error, stackTrace) {
        return ErrorState<ParcelData>(
          errorMessage: error.toString(),
        );
      },
    );
  }

  Future<void> _onLoadUserParcels(
    ParcelLoadUserParcels event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.getUserParcels(event.userId);

    result.fold(
      (failure) {
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (parcels) {
        final updatedData = currentData.copyWith(userParcels: parcels);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));

        add(ParcelWatchUserParcelsRequested(event.userId));
      },
    );
  }

  Future<void> _onWatchAvailableParcelsRequested(
    ParcelWatchAvailableParcelsRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    await _availableParcelsSubscription?.cancel();

    _availableParcelsSubscription = _parcelUseCase
        .watchAvailableParcels()
        .listen(
          (parcelsEither) {
            parcelsEither.fold(
              (failure) {
              },
              (parcels) {
                add(ParcelAvailableListUpdated(parcels));
              },
            );
          },
          onError: (error) {
          },
        );
  }

  Future<void> _onAvailableListUpdated(
    ParcelAvailableListUpdated event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    final updatedData = currentData.copyWith(availableParcels: event.parcels);
    emit(LoadedState<ParcelData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onAssignTravelerRequested(
    ParcelAssignTravelerRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.assignTraveler(
      event.parcelId,
      event.travelerId,
    );

    result.fold(
      (failure) {
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _parcelStatusSubscription?.cancel();
    _userParcelsSubscription?.cancel();
    _availableParcelsSubscription?.cancel();
    return super.close();
  }
}
