import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class KycRemoteDataSource {
  Future<void> submitKyc({
    required String userId,
    required String fullName,
    required String dateOfBirth,
    required String address,
    required String idType,
    required String idNumber,
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  });


  Stream<String> watchKycStatus(String userId);
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  KycRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<void> submitKyc({
    required String userId,
    required String fullName,
    required String dateOfBirth,
    required String address,
    required String idType,
    required String idNumber,
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  }) async {
    try {
      final frontImageUrl = await _uploadImage(frontImagePath, '$userId/front');
      final backImageUrl = await _uploadImage(backImagePath, '$userId/back');
      final selfieImageUrl = await _uploadImage(selfieImagePath, '$userId/selfie');

      final kycData = {
        'userId': userId,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'idType': idType,
        'idNumber': idNumber,
        'frontImageUrl': frontImageUrl,
        'backImageUrl': backImageUrl,
        'selfieImageUrl': selfieImageUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await firestore.collection('kyc_submissions').doc(userId).set(kycData);

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
        .map((snapshot) {
      if (!snapshot.exists) {
        return 'not_submitted';
      }
      return snapshot.data()?['kycStatus'] ?? 'not_submitted';
    });
  }

  Future<String> _uploadImage(String imagePath, String storagePath) async {
    try {
      final file = File(imagePath);
      final ref = storage.ref().child('kyc/$storagePath');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
