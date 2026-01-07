import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/usecases/parcel_usecase.dart';

// Events
abstract class ActivePackagesEvent {}

class LoadActivePackages extends ActivePackagesEvent {
  final String userId;
  LoadActivePackages(this.userId);
}

class _ActivePackagesStreamUpdated extends ActivePackagesEvent {
  final List<PackageEntity> packages;
  _ActivePackagesStreamUpdated(this.packages);
}

class _ActivePackagesStreamFailed extends ActivePackagesEvent {
  final String message;
  _ActivePackagesStreamFailed(this.message);
}

// BLoC
class ActivePackagesBloc extends Bloc<ActivePackagesEvent, BaseState<List<PackageEntity>>> {
  final _parcelUseCase = ParcelUseCase();
  StreamSubscription? _parcelsSubscription;

  ActivePackagesBloc() : super(const InitialState<List<PackageEntity>>()) {
    on<LoadActivePackages>(_onLoadActivePackages);
    on<_ActivePackagesStreamUpdated>(_onStreamUpdated);
    on<_ActivePackagesStreamFailed>(_onStreamFailed);
  }

  Future<void> _onLoadActivePackages(
    LoadActivePackages event,
    Emitter<BaseState<List<PackageEntity>>> emit,
  ) async {
    emit(const LoadingState<List<PackageEntity>>());

    await _parcelsSubscription?.cancel();

    _parcelsSubscription = _parcelUseCase.watchUserParcels(event.userId).listen(
      (result) {
        result.fold(
          (failure) {
            if (isClosed) return;
            add(_ActivePackagesStreamFailed(failure.failureMessage));
          },
          (parcels) {
            if (isClosed) return;
            // Convert ParcelEntity list to PackageEntity list
            // For now, return empty list as PackageEntity structure differs
            add(_ActivePackagesStreamUpdated(const <PackageEntity>[]));
          },
        );
      },
    );
  }

  Future<void> _onStreamUpdated(
    _ActivePackagesStreamUpdated event,
    Emitter<BaseState<List<PackageEntity>>> emit,
  ) async {
    emit(LoadedState<List<PackageEntity>>(
      data: event.packages,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onStreamFailed(
    _ActivePackagesStreamFailed event,
    Emitter<BaseState<List<PackageEntity>>> emit,
  ) async {
    emit(ErrorState<List<PackageEntity>>(errorMessage: event.message));
  }

  @override
  Future<void> close() {
    _parcelsSubscription?.cancel();
    return super.close();
  }
}
