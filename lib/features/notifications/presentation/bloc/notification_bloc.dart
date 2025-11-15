import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/notification_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationUseCase notificationUseCase;
  StreamSubscription? _notificationsSubscription;

  NotificationBloc({required this.notificationUseCase})
      : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAll>(_onClearAll);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationsLoading());

    await _notificationsSubscription?.cancel();

    await emit.forEach<dynamic>(
      notificationUseCase.watchNotifications(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => NotificationError(failure.failureMessage),
          (notifications) {
            final unreadCount = notifications.where((n) => !n.isRead).length;
            return NotificationsLoaded(
              notifications: notifications,
              unreadCount: unreadCount,
            );
          },
        );
      },
      onError: (error, stackTrace) {
        return NotificationError(error.toString());
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationUseCase.markAsRead(event.notificationId);

    result.fold(
      (failure) => emit(NotificationError(failure.failureMessage)),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationUseCase.markAllAsRead(event.userId);

    result.fold(
      (failure) => emit(NotificationError(failure.failureMessage)),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    final result =
        await notificationUseCase.deleteNotification(event.notificationId);

    result.fold(
      (failure) => emit(NotificationError(failure.failureMessage)),
      (_) {
        // Stream will automatically update the state
      },
    );
  }

  Future<void> _onClearAll(
    ClearAll event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationUseCase.clearAll(event.userId);

    result.fold(
      (failure) => emit(NotificationError(failure.failureMessage)),
      (_) {
        emit(NotificationInitial());
      },
    );
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
