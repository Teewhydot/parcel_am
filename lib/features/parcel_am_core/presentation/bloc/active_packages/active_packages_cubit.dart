import 'package:dartz/dartz.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/errors/failures.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../../domain/usecases/parcel_usecase.dart';

class ActivePackagesCubit extends BaseCubit<BaseState<List<PackageEntity>>> {
  final _parcelUseCase = ParcelUseCase();

  ActivePackagesCubit() : super(const InitialState<List<PackageEntity>>());

  /// Stream for watching user parcels - use with StreamBuilder
  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(String userId) async* {
    try {
      yield* _parcelUseCase.watchUserParcels(userId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  Future<void> loadActivePackages(String userId) async {
    emit(const LoadingState<List<PackageEntity>>());

    final result = await _parcelUseCase.getUserParcels(userId);

    result.fold(
      (failure) {
        emit(ErrorState<List<PackageEntity>>(errorMessage: failure.failureMessage));
      },
      (parcels) {
        emit(LoadedState<List<PackageEntity>>(
          data: const <PackageEntity>[],
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }
}
