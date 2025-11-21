import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../domain/entities/uploaded_file_entity.dart';

abstract class FileUploadDataSource {
  Future<UploadedFileEntity> uploadFile({
    required String userId,
    required File file,
  });

  Future<void> deleteFile({required String fileId});

  Future<String> generateUrl({
    required String filePath,
    List<String>? transformations,
  });
}

class FirebaseFileUploadImpl implements FileUploadDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  FirebaseFileUploadImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _auth = auth,
        _storage = storage;

  @override
  Future<void> deleteFile({required String fileId}) async {
    try {
      // fileId can be either a storage path or download URL
      if (fileId.startsWith('http')) {
        final ref = _storage.refFromURL(fileId);
        await ref.delete();
      } else {
        final ref = _storage.ref().child(fileId);
        await ref.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  @override
  Future<String> generateUrl({
    required String filePath,
    List<String>? transformations,
  }) async {
    try {
      // If filePath is already a URL, return it
      if (filePath.startsWith('http')) {
        return filePath;
      }

      // Otherwise, get the download URL from the storage path
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to generate URL: $e');
    }
  }

  @override
  Future<UploadedFileEntity> uploadFile({
    required String userId,
    required File file,
  }) async {
    try {
      // Create a reference to the location you want to upload to in firebase
      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(file);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update the user's profile with the new image URL
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile photo
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePhotoURL(downloadUrl);
      }

      return UploadedFileEntity(url: downloadUrl, uploadedAt: DateTime.now());
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }
}
