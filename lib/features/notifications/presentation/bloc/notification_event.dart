import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to trigger notification stream subscription
class LoadNotifications extends NotificationEvent {
  final String userId;

  const LoadNotifications(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Event to mark a single notification as read
class MarkAsRead extends NotificationEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

/// Event to mark all notifications as read
class MarkAllAsRead extends NotificationEvent {
  final String userId;

  const MarkAllAsRead(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Event to delete a single notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

/// Event to clear all notifications
class ClearAll extends NotificationEvent {
  final String userId;

  const ClearAll(this.userId);

  @override
  List<Object> get props => [userId];
}
