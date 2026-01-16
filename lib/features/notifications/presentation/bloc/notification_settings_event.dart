import 'package:equatable/equatable.dart';

/// Base class for notification settings events
abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load notification settings for a user
class LoadNotificationSettings extends NotificationSettingsEvent {
  final String userId;

  const LoadNotificationSettings(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Toggle a specific notification setting
class ToggleNotificationSetting extends NotificationSettingsEvent {
  final String settingKey;
  final bool value;

  const ToggleNotificationSetting({
    required this.settingKey,
    required this.value,
  });

  @override
  List<Object?> get props => [settingKey, value];
}

/// Save notification settings to Firestore
class SaveNotificationSettings extends NotificationSettingsEvent {
  final String userId;

  const SaveNotificationSettings(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Reset notification settings to defaults
class ResetNotificationSettings extends NotificationSettingsEvent {
  const ResetNotificationSettings();
}
