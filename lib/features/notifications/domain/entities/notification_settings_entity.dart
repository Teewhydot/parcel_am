import 'package:equatable/equatable.dart';

/// Entity representing user notification preferences
class NotificationSettingsEntity extends Equatable {
  /// Enable/disable chat message notifications
  final bool chatMessages;

  /// Enable/disable parcel update notifications
  final bool parcelUpdates;

  /// Enable/disable escrow alert notifications
  final bool escrowAlerts;

  /// Enable/disable system announcement notifications
  final bool systemAnnouncements;

  const NotificationSettingsEntity({
    this.chatMessages = true,
    this.parcelUpdates = true,
    this.escrowAlerts = true,
    this.systemAnnouncements = true,
  });

  /// Default settings with all notifications enabled
  factory NotificationSettingsEntity.defaultSettings() {
    return const NotificationSettingsEntity(
      chatMessages: true,
      parcelUpdates: true,
      escrowAlerts: true,
      systemAnnouncements: true,
    );
  }

  /// Convert to Cloud Function's notificationPreferences array format
  /// This is used for backward compatibility with the Cloud Function
  /// that checks user preferences before sending notifications
  List<String> toPreferencesArray() {
    final preferences = <String>[];

    if (chatMessages) {
      preferences.add('chat');
    }
    if (parcelUpdates) {
      preferences.add('general');
    }
    if (escrowAlerts) {
      preferences.add('payment');
    }
    if (systemAnnouncements) {
      preferences.add('appUpdate');
    }

    return preferences;
  }

  /// Create a copy with updated values
  NotificationSettingsEntity copyWith({
    bool? chatMessages,
    bool? parcelUpdates,
    bool? escrowAlerts,
    bool? systemAnnouncements,
  }) {
    return NotificationSettingsEntity(
      chatMessages: chatMessages ?? this.chatMessages,
      parcelUpdates: parcelUpdates ?? this.parcelUpdates,
      escrowAlerts: escrowAlerts ?? this.escrowAlerts,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
    );
  }

  @override
  List<Object?> get props => [
        chatMessages,
        parcelUpdates,
        escrowAlerts,
        systemAnnouncements,
      ];
}
