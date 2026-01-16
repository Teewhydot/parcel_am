import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

/// Service for handling Firebase Storage operations with progress tracking,
/// compression, and retry logic
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Maximum number of retry attempts for failed uploads
  static const int maxRetryAttempts = 3;

  /// Maximum file size in bytes (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Target file size after compression (2MB)
  static const int targetCompressedSize = 2 * 1024 * 1024;

  /// Quality for image compression (0-100)
  static const int compressionQuality = 85;

  /// Upload a file to Firebase Storage with progress tracking and retry logic
  ///
  /// [file] - The file to upload
  /// [storagePath] - The path in Firebase Storage (e.g., 'kyc/{userId}/government_id.jpg')
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  /// [compress] - Whether to compress the image before upload
  /// [retryCount] - Current retry attempt (used internally)
  ///
  /// Returns the download URL of the uploaded file
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    Function(double progress)? onProgress,
    bool compress = true,
    int retryCount = 0,
  }) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Validate file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('File size exceeds maximum limit of ${maxFileSize ~/ (1024 * 1024)}MB');
      }

      File fileToUpload = file;

      // Compress image if requested and it's an image file
      if (compress && _isImageFile(file.path)) {
        onProgress?.call(0.1); // 10% - Starting compression
        fileToUpload = await _compressImage(file);
        onProgress?.call(0.2); // 20% - Compression complete
      }

      // Create reference
      final ref = _storage.ref().child(storagePath);

      // Upload with progress tracking
      final uploadTask = ref.putFile(fileToUpload);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null && snapshot.totalBytes > 0) {
          // Map upload progress from 20% to 90%
          final uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          final totalProgress = 0.2 + (uploadProgress * 0.7);
          onProgress(totalProgress);
        }
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      onProgress?.call(0.95); // 95% - Upload complete, getting URL

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      onProgress?.call(1.0); // 100% - Complete

      // Clean up compressed file if different from original
      if (compress && fileToUpload.path != file.path) {
        try {
          await fileToUpload.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      // Retry logic for network errors
      if (retryCount < maxRetryAttempts && _isRetryableError(e)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return uploadFile(
          file: file,
          storagePath: storagePath,
          onProgress: onProgress,
          compress: compress,
          retryCount: retryCount + 1,
        );
      }
      throw _handleFirebaseError(e);
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  /// Upload a KYC document with standardized naming
  ///
  /// [file] - The document file to upload
  /// [userId] - The user's ID
  /// [documentType] - Type of document (government_id, selfie_with_id, proof_of_address)
  /// [onProgress] - Optional callback for upload progress
  ///
  /// Returns the download URL
  Future<String> uploadKycDocument({
    required File file,
    required String userId,
    required String documentType,
    Function(double progress)? onProgress,
  }) async {
    final extension = path.extension(file.path);
    final storagePath = 'kyc/$userId/documents/$documentType$extension';

    return uploadFile(
      file: file,
      storagePath: storagePath,
      onProgress: onProgress,
      compress: true,
    );
  }

  /// Delete a file from Firebase Storage
  ///
  /// [storagePath] - The path of the file to delete
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        throw _handleFirebaseError(e);
      }
      // Ignore if file doesn't exist
    }
  }

  /// Delete a file using its download URL
  ///
  /// [downloadUrl] - The download URL of the file
  Future<void> deleteFileByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        throw _handleFirebaseError(e);
      }
      // Ignore if file doesn't exist
    }
  }

  /// Compress an image file
  ///
  /// [file] - The image file to compress
  ///
  /// Returns the compressed file
  Future<File> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitPath = filePath.substring(0, lastIndex);
      final outPath = '${splitPath}_compressed${path.extension(filePath)}';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: compressionQuality,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (result == null) {
        // If compression fails, return original file
        return file;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      // If compressed file is still too large or larger than original, use original
      if (compressedSize > targetCompressedSize * 1.5 || compressedSize > await file.length()) {
        await compressedFile.delete();
        return file;
      }

      return compressedFile;
    } catch (e) {
      // If compression fails, return original file
      return file;
    }
  }

  /// Check if a file is an image based on extension
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.heic', '.webp'].contains(extension);
  }

  /// Check if a Firebase error is retryable
  bool _isRetryableError(FirebaseException e) {
    return ['network-request-failed', 'timeout', 'unavailable'].contains(e.code);
  }

  /// Handle Firebase errors with user-friendly messages
  Exception _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return Exception('You do not have permission to upload files. Please try again.');
      case 'canceled':
        return Exception('Upload was canceled');
      case 'unknown':
        return Exception('An unknown error occurred. Please try again.');
      case 'object-not-found':
        return Exception('File not found');
      case 'bucket-not-found':
        return Exception('Storage bucket not found. Please contact support.');
      case 'quota-exceeded':
        return Exception('Storage quota exceeded. Please contact support.');
      case 'unauthenticated':
        return Exception('You must be logged in to upload files');
      case 'retry-limit-exceeded':
        return Exception('Upload failed after multiple attempts. Please check your connection and try again.');
      default:
        return Exception('Upload failed: ${e.message ?? e.code}');
    }
  }
}
