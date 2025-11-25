import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/parcel_am_core/domain/entities/parcel_entity.dart';

/// Service for queuing parcel status updates when offline.
///
/// Features:
/// - Queue status updates when no internet connection
/// - Persist queue to local storage
/// - Sync queued updates when connection is restored
/// - Automatic retry with error handling
///
/// Task Group 4.2.1: Offline scenario handling
class OfflineQueueService {
  static const String _queueKey = 'offline_status_update_queue';
  final SharedPreferences _prefs;

  OfflineQueueService(this._prefs);

  /// Queues a status update for later sync.
  ///
  /// Stores parcelId and status to be updated when connection is restored.
  Future<void> queueStatusUpdate(String parcelId, ParcelStatus status) async {
    try {
      final queue = await _getQueue();

      // Check if this parcel already has a queued update
      final existingIndex = queue.indexWhere((item) => item['parcelId'] == parcelId);

      final updateItem = {
        'parcelId': parcelId,
        'status': status.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (existingIndex != -1) {
        // Replace existing queued update for this parcel
        queue[existingIndex] = updateItem;
      } else {
        // Add new queued update
        queue.add(updateItem);
      }

      await _saveQueue(queue);
    } catch (e) {
      // Log error but don't throw - offline queue is not critical
      print('Error queuing status update: $e');
    }
  }

  /// Returns all queued status updates.
  ///
  /// Returns a list of maps containing parcelId, status, and timestamp.
  Future<List<Map<String, dynamic>>> getQueuedUpdates() async {
    return await _getQueue();
  }

  /// Removes a status update from the queue.
  ///
  /// Called after successfully syncing an update to the server.
  Future<void> removeFromQueue(String parcelId) async {
    try {
      final queue = await _getQueue();
      queue.removeWhere((item) => item['parcelId'] == parcelId);
      await _saveQueue(queue);
    } catch (e) {
      print('Error removing item from queue: $e');
    }
  }

  /// Clears all queued updates.
  ///
  /// Use cautiously - typically only after successful bulk sync.
  Future<void> clearQueue() async {
    try {
      await _prefs.remove(_queueKey);
    } catch (e) {
      print('Error clearing queue: $e');
    }
  }

  /// Returns the number of queued updates.
  Future<int> getQueueSize() async {
    final queue = await _getQueue();
    return queue.length;
  }

  /// Checks if a specific parcel has a queued update.
  Future<bool> hasQueuedUpdate(String parcelId) async {
    final queue = await _getQueue();
    return queue.any((item) => item['parcelId'] == parcelId);
  }

  /// Gets the queued status for a specific parcel if it exists.
  Future<ParcelStatus?> getQueuedStatus(String parcelId) async {
    final queue = await _getQueue();
    final item = queue.firstWhere(
      (item) => item['parcelId'] == parcelId,
      orElse: () => <String, dynamic>{},
    );

    if (item.isEmpty || item['status'] == null) {
      return null;
    }

    try {
      return ParcelStatus.fromString(item['status'] as String);
    } catch (e) {
      return null;
    }
  }

  // Private helper methods

  /// Retrieves the queue from local storage.
  Future<List<Map<String, dynamic>>> _getQueue() async {
    try {
      final queueJson = _prefs.getString(_queueKey);
      if (queueJson == null || queueJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(queueJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error reading queue: $e');
      return [];
    }
  }

  /// Saves the queue to local storage.
  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    try {
      final queueJson = jsonEncode(queue);
      await _prefs.setString(_queueKey, queueJson);
    } catch (e) {
      print('Error saving queue: $e');
    }
  }
}
