import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../domain/usecases/notification_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, BaseState<NotificationData>> {
  final notificationUseCase = NotificationUseCase();
  StreamSubscription? _notificationsSubscription;

  NotificationBloc()
      : super(const InitialState<NotificationData>()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAll>(_onClearAll);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<BaseState<NotificationData>> emit,
  ) async {
    emit(const LoadingState<NotificationData>());

    await _notificationsSubscription?.cancel();

    await emit.forEach<dynamic>(
      notificationUseCase.watchNotifications(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => ErrorState<NotificationData>(
            errorMessage: failure.failureMessage,
          ),
          (notifications) {
            final unreadCount = notifications.where((n) => !n.isRead).length;
            return LoadedState<NotificationData>(
              data: NotificationData(
                notifications: notifications,
                unreadCount: unreadCount,
              ),
            );
          },
        );
      },
      onError: (error, stackTrace) {
        return ErrorState<NotificationData>(
          errorMessage: error.toString(),
        );
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<BaseState<NotificationData>> emit,
  ) async {
    final result = await notificationUseCase.markAsRead(event.notificationId);

    result.fold(
      (failure) => emit(ErrorState<NotificationData>(
        errorMessage: failure.failureMessage,
      )),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<BaseState<NotificationData>> emit,
  ) async {
    final result = await notificationUseCase.markAllAsRead(event.userId);

    result.fold(
      (failure) => emit(ErrorState<NotificationData>(
        errorMessage: failure.failureMessage,
      )),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<BaseState<NotificationData>> emit,
  ) async {
    final result =
        await notificationUseCase.deleteNotification(event.notificationId);

    result.fold(
      (failure) => emit(ErrorState<NotificationData>(
        errorMessage: failure.failureMessage,
      )),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> _onClearAll(
    ClearAll event,
    Emitter<BaseState<NotificationData>> emit,
  ) async {
    final result = await notificationUseCase.clearAll(event.userId);

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

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
