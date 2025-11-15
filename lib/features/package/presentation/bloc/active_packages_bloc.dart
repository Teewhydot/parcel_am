import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/package_entity.dart';
import '../../domain/usecases/watch_active_packages.dart';

// Events
abstract class ActivePackagesEvent extends Equatable {
  const ActivePackagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivePackages extends ActivePackagesEvent {
  final String userId;

  const LoadActivePackages(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class ActivePackagesState extends Equatable {
  const ActivePackagesState();

  @override
  List<Object?> get props => [];
}

class ActivePackagesInitial extends ActivePackagesState {}

class ActivePackagesLoading extends ActivePackagesState {}

class ActivePackagesLoaded extends ActivePackagesState {
  final List<PackageEntity> packages;

  const ActivePackagesLoaded(this.packages);

  @override
  List<Object?> get props => [packages];
}

class ActivePackagesError extends ActivePackagesState {
  final String message;

  const ActivePackagesError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ActivePackagesBloc extends Bloc<ActivePackagesEvent, ActivePackagesState> {
  final watchActivePackages = WatchActivePackages();
  StreamSubscription? _packagesSubscription;

  ActivePackagesBloc() : super(ActivePackagesInitial()) {
    on<LoadActivePackages>(_onLoadActivePackages);
  }

  Future<void> _onLoadActivePackages(
    LoadActivePackages event,
    Emitter<ActivePackagesState> emit,
  ) async {
    emit(ActivePackagesLoading());

    await _packagesSubscription?.cancel();

    _packagesSubscription = watchActivePackages(event.userId).listen(
      (result) {
        result.fold(
          (failure) {
            if (!isClosed) {
              emit(ActivePackagesError(failure.failureMessage));
            }
          },
          (packages) {
            if (!isClosed) {
              emit(ActivePackagesLoaded(packages));
            }
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _packagesSubscription?.cancel();
    return super.close();
  }
}
