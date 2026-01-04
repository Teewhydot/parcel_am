import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/funding_order_entity.dart';

/// Remote data source for funding order operations.
abstract class FundingOrderRemoteDataSource {
  /// Watches the status of a funding order in real-time.
  Stream<FundingOrderEntity> watchFundingOrderStatus(String reference);

  /// Gets the current status of a funding order.
  Future<FundingOrderEntity> getFundingOrderStatus(String reference);
}

/// Implementation of [FundingOrderRemoteDataSource] using Firestore.
class FundingOrderRemoteDataSourceImpl implements FundingOrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  FundingOrderRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<FundingOrderEntity> watchFundingOrderStatus(String reference) {
    final fundingOrderId = 'F-$reference';

    return _firestore
        .collection('funding_orders')
        .doc(fundingOrderId)
        .snapshots()
        .map((snapshot) => _mapToEntity(snapshot, reference));
  }

  @override
  Future<FundingOrderEntity> getFundingOrderStatus(String reference) async {
    final fundingOrderId = 'F-$reference';

    final snapshot = await _firestore
        .collection('funding_orders')
        .doc(fundingOrderId)
        .get();

    return _mapToEntity(snapshot, reference);
  }

  FundingOrderEntity _mapToEntity(
      DocumentSnapshot<Map<String, dynamic>> snapshot, String reference) {
    if (!snapshot.exists) {
      throw Exception('Funding order not found: F-$reference');
    }

    final data = snapshot.data()!;
    return FundingOrderEntity(
      id: snapshot.id,
      reference: reference,
      userId: data['userId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
