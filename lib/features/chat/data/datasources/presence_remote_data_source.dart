import 'dart:async';
import '../models/presence_model.dart';
import '../../domain/entities/presence_entity.dart';
import '../../../../core/utils/logger.dart';
import '../../services/presence_rtdb_service.dart';

abstract class PresenceRemoteDataSource {
  Stream<PresenceModel> watchUserPresence(String userId);
  Future<void> updatePresenceStatus(String userId, PresenceStatus status);
  Future<void> updateTypingStatus(String userId, String? chatId, bool isTyping);
  Future<void> updateLastSeen(String userId);
  Future<PresenceModel?> getUserPresence(String userId);
}

/// Implementation using Firebase Realtime Database for lower latency
/// Migrated from Firestore to RTDB for ~50ms latency vs 200-500ms
class PresenceRemoteDataSourceImpl implements PresenceRemoteDataSource {
  final PresenceRtdbService _rtdbService;

  PresenceRemoteDataSourceImpl({PresenceRtdbService? rtdbService})
      : _rtdbService = rtdbService ?? PresenceRtdbService();

  @override
  Stream<PresenceModel> watchUserPresence(String userId) {
    return _rtdbService.watchPresence(userId).map((presenceData) {
      return PresenceModel(
        userId: presenceData.userId,
        status: presenceData.status,
        lastSeen: presenceData.lastSeen,
        isTyping: false, // Typing is handled separately by TypingService
        typingInChatId: null,
        lastTypingAt: null,
      );
    }).handleError((error) {
      Logger.logError(
        'RTDB Error (watchUserPresence): $error',
        tag: 'PresenceDataSource',
      );
    });
  }

  @override
  Future<void> updatePresenceStatus(String userId, PresenceStatus status) async {
    try {
      switch (status) {
        case PresenceStatus.online:
          await _rtdbService.setOnline(userId);
          break;
        case PresenceStatus.offline:
          await _rtdbService.setOffline(userId);
          break;
        case PresenceStatus.away:
          await _rtdbService.setAway(userId);
          break;
        case PresenceStatus.typing:
          // Typing is handled by TypingService, just set online here
          await _rtdbService.setOnline(userId);
          break;
      }
    } catch (e) {
      Logger.logError(
        'Failed to update presence status: $e',
        tag: 'PresenceDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTypingStatus(String userId, String? chatId, bool isTyping) async {
    // Typing is now handled by TypingService on RTDB
    // This method is kept for backward compatibility but delegates to TypingService
    // The actual typing logic should be called directly from TypingService
    Logger.logWarning(
      'updateTypingStatus called on PresenceDataSource - use TypingService directly',
      tag: 'PresenceDataSource',
    );
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    try {
      await _rtdbService.updateLastSeen(userId);
    } catch (e) {
      Logger.logError(
        'Failed to update last seen: $e',
        tag: 'PresenceDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<PresenceModel?> getUserPresence(String userId) async {
    try {
      final presenceData = await _rtdbService.getPresence(userId);
      if (presenceData == null) {
        return null;
      }

      return PresenceModel(
        userId: presenceData.userId,
        status: presenceData.status,
        lastSeen: presenceData.lastSeen,
        isTyping: false, // Typing is handled separately by TypingService
        typingInChatId: null,
        lastTypingAt: null,
      );
    } catch (e) {
      Logger.logError(
        'Failed to get user presence: $e',
        tag: 'PresenceDataSource',
      );
      return null;
    }
  }
}
