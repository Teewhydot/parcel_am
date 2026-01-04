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

// BLoC
class ActivePackagesBloc extends Bloc<ActivePackagesEvent, BaseState<List<PackageEntity>>> {
  final _parcelUseCase = ParcelUseCase();
  StreamSubscription? _parcelsSubscription;

  ActivePackagesBloc() : super(const InitialState<List<PackageEntity>>()) {
    on<LoadActivePackages>(_onLoadActivePackages);
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
            if (!isClosed) {
              emit(ErrorState<List<PackageEntity>>(
                errorMessage: failure.failureMessage,
              ));
            }
          },
          (parcels) {
            if (!isClosed) {
              // Convert ParcelEntity list to PackageEntity list
              // For now, return empty list as PackageEntity structure differs
              emit(LoadedState<List<PackageEntity>>(
                data: [],
                lastUpdated: DateTime.now(),
              ));
            }
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _parcelsSubscription?.cancel();
    return super.close();
  }
}
