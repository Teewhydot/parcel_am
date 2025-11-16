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

  ActivePackagesBloc() : super(ActivePackagesInitial()) {
    on<LoadActivePackages>(_onLoadActivePackages);
  }

  Future<void> _onLoadActivePackages(
    LoadActivePackages event,
    Emitter<ActivePackagesState> emit,
  ) async {
    emit(ActivePackagesLoading());

    await emit.forEach<dynamic>(
      watchActivePackages(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => ActivePackagesError(failure.failureMessage),
          (packages) => ActivePackagesLoaded(packages),
        );
      },
    );
  }
}
