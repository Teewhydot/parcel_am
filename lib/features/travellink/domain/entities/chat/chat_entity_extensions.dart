import 'chat_entity.dart';

extension ChatEntityExtensions on ChatEntity {
  /// Get the other participant ID for a 1-on-1 chat
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
  }

  /// Get the participant name (from metadata for now)
  String get participantName {
    // Try to get from metadata first
    final names = metadata['participantNames'] as Map<String, dynamic>?;
    if (names != null && names.isNotEmpty) {
      return names.values.first.toString();
    }
    return 'Unknown User';
  }

  /// Get the participant avatar URL (from metadata)
  String? get participantAvatar {
    final avatars = metadata['participantAvatars'] as Map<String, dynamic>?;
    if (avatars != null && avatars.isNotEmpty) {
      return avatars.values.first?.toString();
    }
    return null;
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Check if chat is pinned (stored in metadata)
  bool get isPinned {
    return metadata['isPinned'] as bool? ?? false;
  }

  /// Check if chat is muted (stored in metadata)
  bool get isMuted {
    return metadata['isMuted'] as bool? ?? false;
  }

  /// Get unread count for current user (convenience getter)
  int get unreadCount {
    // This will be set by the screen with currentUserId
    return 0;
  }

  /// Update metadata for pin status
  ChatEntity withPinned(bool pinned) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata['isPinned'] = pinned;
    return copyWith(metadata: newMetadata);
  }

  /// Update metadata for mute status
  ChatEntity withMuted(bool muted) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata['isMuted'] = muted;
    return copyWith(metadata: newMetadata);
  }

  /// Mark chat as read for a user
  ChatEntity withReadForUser(String userId) {
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    newUnreadCounts[userId] = 0;
    return copyWith(unreadCounts: newUnreadCounts);
  }
}
