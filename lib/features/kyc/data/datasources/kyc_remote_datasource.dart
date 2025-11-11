import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kyc_model.dart';

abstract class KycRemoteDataSource {
  Future<KycModel> submitKyc(
    String userId,
    List<String> documentUrls,
    Map<String, dynamic>? metadata,
  );
  Future<KycModel> getKycStatus(String userId);
  Stream<KycModel> watchKycStatus(String userId);
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String kycCollection = 'kyc';

  KycRemoteDataSourceImpl({required this.firestore});

  @override
  Future<KycModel> submitKyc(
    String userId,
    List<String> documentUrls,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final kycRef = firestore.collection(kycCollection).doc(userId);
      
      final kycData = {
        'userId': userId,
        'status': 'pending',
        'documentUrls': documentUrls,
        'submittedAt': FieldValue.serverTimestamp(),
        'metadata': metadata,
      };

      await kycRef.set(kycData, SetOptions(merge: true));

      final doc = await kycRef.get();
      if (!doc.exists) {
        throw Exception('Failed to submit KYC');
      }

      return KycModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to submit KYC: $e');
    }
  }

  @override
  Future<KycModel> getKycStatus(String userId) async {
    try {
      final doc = await firestore
          .collection(kycCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('KYC not found for user: $userId');
      }

      return KycModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch KYC status: $e');
    }
  }

  @override
  Stream<KycModel> watchKycStatus(String userId) {
    return firestore
        .collection(kycCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('KYC not found for user: $userId');
      }
      return KycModel.fromFirestore(doc);
    });
  }
}
