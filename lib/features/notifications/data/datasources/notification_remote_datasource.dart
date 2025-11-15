import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  /// Watch notifications stream for a specific user
  Stream<List<NotificationModel>> watchNotifications(String userId);

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId);

  /// Delete a specific notification
  Future<void> deleteNotification(String notificationId);

  /// Clear all notifications for a user
  Future<void> clearAll(String userId);

  /// Save a notification to Firestore
  Future<void> saveNotification(NotificationModel notification);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;

  NotificationRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = firestore.batch();
      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> clearAll(String userId) async {
    try {
      final batch = firestore.batch();
      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear all notifications: $e');
    }
  }

  @override
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final notificationData = notification.toJson();

      // If notification has an ID, use it; otherwise let Firestore generate one
      if (notification.id.isNotEmpty) {
        await firestore
            .collection('notifications')
            .doc(notification.id)
            .set(notificationData);
      } else {
        await firestore.collection('notifications').add(notificationData);
      }
    } catch (e) {
      throw Exception('Failed to save notification: $e');
    }
  }
}
