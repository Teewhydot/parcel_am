import '../../domain/entities/notification_settings_entity.dart';

/// Data model for notification settings with JSON serialization
class NotificationSettingsModel extends NotificationSettingsEntity {
  const NotificationSettingsModel({
    super.chatMessages,
    super.parcelUpdates,
    super.escrowAlerts,
    super.systemAnnouncements,
  });

  /// Create from JSON map (Firestore document data)
  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      chatMessages: json['chatMessages'] as bool? ?? true,
      parcelUpdates: json['parcelUpdates'] as bool? ?? true,
      escrowAlerts: json['escrowAlerts'] as bool? ?? true,
      systemAnnouncements: json['systemAnnouncements'] as bool? ?? true,
    );
  }

  /// Create from Firestore document data
  /// Handles both nested notificationSettings object and legacy notificationPreferences array
  factory NotificationSettingsModel.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return const NotificationSettingsModel();
    }

    // Check for nested notificationSettings object first
    final settings = data['notificationSettings'] as Map<String, dynamic>?;
    if (settings != null) {
      return NotificationSettingsModel.fromJson(settings);
    }

    // Fall back to legacy notificationPreferences array
    final preferences = data['notificationPreferences'] as List<dynamic>?;
    if (preferences != null) {
      return NotificationSettingsModel(
        chatMessages: preferences.contains('chat'),
        parcelUpdates: preferences.contains('general'),
        escrowAlerts: preferences.contains('payment'),
        systemAnnouncements: preferences.contains('appUpdate'),
      );
    }

    // Default settings if nothing found
    return const NotificationSettingsModel();
  }

  /// Create from entity
  factory NotificationSettingsModel.fromEntity(NotificationSettingsEntity entity) {
    return NotificationSettingsModel(
      chatMessages: entity.chatMessages,
      parcelUpdates: entity.parcelUpdates,
      escrowAlerts: entity.escrowAlerts,
      systemAnnouncements: entity.systemAnnouncements,
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'chatMessages': chatMessages,
      'parcelUpdates': parcelUpdates,
      'escrowAlerts': escrowAlerts,
      'systemAnnouncements': systemAnnouncements,
    };
  }

  /// Convert to Firestore update map
  /// Updates both the notificationSettings object and the legacy notificationPreferences array
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'notificationSettings': toJson(),
      'notificationPreferences': toPreferencesArray(),
    };
  }

  @override
  NotificationSettingsModel copyWith({
    bool? chatMessages,
    bool? parcelUpdates,
    bool? escrowAlerts,
    bool? systemAnnouncements,
  }) {
    return NotificationSettingsModel(
      chatMessages: chatMessages ?? this.chatMessages,
      parcelUpdates: parcelUpdates ?? this.parcelUpdates,
      escrowAlerts: escrowAlerts ?? this.escrowAlerts,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
    );
  }
}
