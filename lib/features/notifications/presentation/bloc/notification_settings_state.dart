import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_settings_entity.dart';

/// Data class for notification settings state
class NotificationSettingsData extends Equatable {
  final NotificationSettingsEntity settings;
  final bool hasChanges;

  const NotificationSettingsData({
    required this.settings,
    this.hasChanges = false,
  });

  NotificationSettingsData copyWith({
    NotificationSettingsEntity? settings,
    bool? hasChanges,
  }) {
    return NotificationSettingsData(
      settings: settings ?? this.settings,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }

  @override
  List<Object?> get props => [settings, hasChanges];
}
