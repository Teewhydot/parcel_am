import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/escrow_notification_repository.dart';

class EscrowNotificationRepositoryImpl implements EscrowNotificationRepository {
  final FirebaseFirestore _firestore;

  EscrowNotificationRepositoryImpl(this._firestore);

  @override
  Stream<EscrowNotification> watchUserEscrowNotifications(String userId) {
    return _firestore
        .collection('packages')
        .where('senderId', isEqualTo: userId)
        .where('paymentInfo.isEscrow', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docChanges)
        .expand((changes) => changes)
        .where((change) => change.type == DocumentChangeType.modified)
        .map((change) {
          final data = change.doc.data();
          if (data == null) return null;
          final paymentInfo = data['paymentInfo'] as Map<String, dynamic>?;
          if (paymentInfo == null) return null;
          final escrowStatus = paymentInfo['escrowStatus'] as String?;
          if (escrowStatus == null) return null;
          return EscrowNotification(
            packageId: change.doc.id,
            packageTitle: data['title'] ?? 'Package',
            status: escrowStatus,
            timestamp: DateTime.now(),
          );
        })
        .where((n) => n != null)
        .cast<EscrowNotification>();
  }
}
