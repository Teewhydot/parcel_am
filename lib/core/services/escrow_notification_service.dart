import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  StreamSubscription? _escrowNotificationSubscription;
  final _notificationController = StreamController<EscrowNotification>.broadcast();

  NotificationService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Stream<EscrowNotification> get escrowNotifications => _notificationController.stream;

  void subscribeToEscrowNotifications(String userId) {
    _escrowNotificationSubscription?.cancel();

    _escrowNotificationSubscription = _firestore
        .collection('packages')
        .where('senderId', isEqualTo: userId)
        .where('paymentInfo.isEscrow', isEqualTo: true)
        .snapshots()
        .listen(
      (snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data != null) {
              final paymentInfo = data['paymentInfo'] as Map<String, dynamic>?;
              if (paymentInfo != null) {
                final escrowStatus = paymentInfo['escrowStatus'] as String?;
                if (escrowStatus != null) {
                  _notificationController.add(
                    EscrowNotification(
                      packageId: change.doc.id,
                      packageTitle: data['title'] ?? 'Package',
                      status: escrowStatus,
                      timestamp: DateTime.now(),
                    ),
                  );
                }
              }
            }
          }
        }
      },
      onError: (error) {
        print('❌ Firestore Error (EscrowNotifications): $error');
        if (error.toString().contains('index')) {
          print('🔍 INDEX REQUIRED: Create a composite index for:');
          print('   Collection: packages');
          print('   Fields: senderId (Ascending), paymentInfo.isEscrow (Ascending)');
          print('   Or visit the Firebase Console to create the index automatically.');
        }
      },
    );
  }

  void unsubscribe() {
    _escrowNotificationSubscription?.cancel();
  }

  void dispose() {
    _escrowNotificationSubscription?.cancel();
    _notificationController.close();
  }
}

class EscrowNotification {
  final String packageId;
  final String packageTitle;
  final String status;
  final DateTime timestamp;

  EscrowNotification({
    required this.packageId,
    required this.packageTitle,
    required this.status,
    required this.timestamp,
  });

  String get message {
    switch (status) {
      case 'held':
        return 'Escrow funds held for $packageTitle';
      case 'released':
        return 'Escrow funds released for $packageTitle';
      case 'disputed':
        return 'Dispute filed for $packageTitle escrow';
      case 'cancelled':
        return 'Escrow cancelled for $packageTitle';
      default:
        return 'Escrow status updated for $packageTitle';
    }
  }
}
