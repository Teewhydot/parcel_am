import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/bloc/base/base_state.dart';
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

// BLoC
class ActivePackagesBloc extends Bloc<ActivePackagesEvent, BaseState<List<PackageEntity>>> {
  final watchActivePackages = WatchActivePackages();

  ActivePackagesBloc() : super(const InitialState<List<PackageEntity>>()) {
    on<LoadActivePackages>(_onLoadActivePackages);
  }

  Future<void> _onLoadActivePackages(
    LoadActivePackages event,
    Emitter<BaseState<List<PackageEntity>>> emit,
  ) async {
    emit(const LoadingState<List<PackageEntity>>());

    await emit.forEach<dynamic>(
      watchActivePackages(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => ErrorState<List<PackageEntity>>(
            errorMessage: failure.failureMessage,
          ),
          (packages) => LoadedState<List<PackageEntity>>(data: packages),
        );
      },
    );
  }
}
