import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_imagekit/flutter_imagekit.dart';
import 'package:parcel_am/core/constants/env.dart';
import '../../../domain/entities/uploaded_file_entity.dart';

abstract class FileUploadDataSource {
  Future<UploadedFileEntity> uploadFile({
    required String userId,
    required File file,
    required String folderPath,
  });

  Future<void> deleteFile({required String fileId});

  Future<String> generateUrl({
    required String filePath,
    List<String>? transformations,
  });
}

class FirebaseFileUploadImpl implements FileUploadDataSource {
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
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
    required String folderPath,
  }) async {
    try {
      // Get file extension from actual file
      final extension = path.extension(file.path);

      // Create timestamp for unique filenames
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp$extension';

      // Create a reference to the location you want to upload to in firebase
      final storageRef = _storage
          .ref()
          .child(folderPath)
          .child(fileName);

      // Upload the file
      final uploadTask = await storageRef.putFile(file);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Only update profile for profile_images folder
      if (folderPath == 'profile_images') {
        // Update the user's profile with the new image URL
        await _firestore.collection('users').doc(userId).update({
          'profileImageUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update Firebase Auth profile photo
        if (_auth.currentUser != null) {
          await _auth.currentUser!.updatePhotoURL(downloadUrl);
        }
      }

      return UploadedFileEntity(url: downloadUrl, uploadedAt: DateTime.now());
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
}


class ImageKitFileUploadImpl implements FileUploadDataSource {
  final baseUrl = "https://ik.imagekit.io/szxwvslzo/";
  final _firestore = FirebaseFirestore.instance;
  @override
  Future<UploadedFileEntity> uploadFile({
    required String userId,
    required File file,
    required String folderPath,
  }) async {
    return ImageKit.io(
    file,
    folder: folderPath, // (Optional)
    privateKey: Env.imageKitPrivateKey!, // (Keep Confidential)
  ).then((String url)async{
      await _firestore.collection('users').doc(userId).update({
          'profileImageUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      return UploadedFileEntity(url: url, uploadedAt: DateTime.now());
  });
  }

  @override
  Future<void> deleteFile({required String fileId}) {
    throw UnimplementedError('ImageKit file deletion not implemented yet');
  }

  @override
  Future<String> generateUrl({
    required String filePath,
    List<String>? transformations,
  }) {
    throw UnimplementedError('ImageKit URL generation not implemented yet');
  }
}