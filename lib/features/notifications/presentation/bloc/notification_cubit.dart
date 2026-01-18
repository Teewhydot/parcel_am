import 'package:dartz/dartz.dart';
import '../../../../core/bloc/base/base_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecase.dart';
import 'notification_state.dart';

class NotificationCubit extends BaseCubit<BaseState<NotificationData>> {
  final notificationUseCase = NotificationUseCase();

  NotificationCubit() : super(const InitialState<NotificationData>());

  /// Stream for watching notifications - use with StreamBuilder
  Stream<Either<Failure, List<NotificationEntity>>> watchNotifications(String userId) async* {
    try {
      yield* notificationUseCase.watchNotifications(userId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final result = await notificationUseCase.markAsRead(notificationId);

    result.fold(
      (failure) => emit(ErrorState<NotificationData>(
        errorMessage: failure.failureMessage,
      )),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final result = await notificationUseCase.markAllAsRead(userId);

    result.fold(
      (failure) => emit(ErrorState<NotificationData>(
        errorMessage: failure.failureMessage,
      )),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    final result = await notificationUseCase.deleteNotification(notificationId);

    result.fold(
      (failure) => emit(ErrorState<NotificationData>(
        errorMessage: failure.failureMessage,
      )),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> clearAll(String userId) async {
    final result = await notificationUseCase.clearAll(userId);

    result.fold(
      (failure) => emit(ErrorState<NotificationData>(
        errorMessage: failure.failureMessage,
      )),
      (_) {
        emit(const EmptyState<NotificationData>(
          message: 'All notifications cleared',
        ));
      },
    );
  }
}
