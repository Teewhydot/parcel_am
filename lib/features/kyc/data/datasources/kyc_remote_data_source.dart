import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/utils/logger.dart';

abstract class KycRemoteDataSource {
  Future<void> submitKyc({
    required String userId,
    required String fullName,
    required DateTime dateOfBirth,
    required String phoneNumber,
    required String email,
    required String address,
    required String city,
    required String country,
    required String postalCode,
    String? governmentIdNumber,
    String? idType,
    String? governmentIdUrl,
    String? selfieWithIdUrl,
    String? proofOfAddressUrl,
  });

  Stream<String> watchKycStatus(String userId);
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  @override
  Future<void> submitKyc({
    required String userId,
    required String fullName,
    required DateTime dateOfBirth,
    required String phoneNumber,
    required String email,
    required String address,
    required String city,
    required String country,
    required String postalCode,
    String? governmentIdNumber,
    String? idType,
    String? governmentIdUrl,
    String? selfieWithIdUrl,
    String? proofOfAddressUrl,
  }) async {
    try {
      final kycData = {
        'userId': userId,
        'fullName': fullName,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'phoneNumber': phoneNumber,
        'email': email,
        'address': address,
        'city': city,
        'country': country,
        'postalCode': postalCode,
        'governmentIdNumber': governmentIdNumber,
        'idType': idType,
        'governmentIdUrl': governmentIdUrl,
        'selfieWithIdUrl': selfieWithIdUrl,
        'proofOfAddressUrl': proofOfAddressUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      // Save to kyc_submissions collection
      await firestore.collection('kyc_submissions').doc(userId).set(kycData);

      // Update user's KYC status
      await firestore.collection('users').doc(userId).update({
        'kycStatus': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to submit KYC: $e');
    }
  }

  @override
  Stream<String> watchKycStatus(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (watchKycStatus): $error', tag: 'KycDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Check Firebase Console for index requirements', tag: 'KycDataSource');
      }
    })
        .map((snapshot) {
      if (!snapshot.exists) {
        return 'not_submitted';
      }
      return snapshot.data()?['kycStatus'] ?? 'not_submitted';
    });
  }
}
