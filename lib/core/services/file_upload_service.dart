import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:parcel_am/core/services/permission_service/permission_service.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/logger.dart';
import 'firebase_storage_service.dart';

enum FileUploadType { image, video, audio, document, any }

/// File upload service that handles file selection and Firebase Storage uploads
class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final PermissionService _permissionService = PermissionService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) throw Exception('Camera permission denied');
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      Logger.logBasic("Picked file: ${pickedFile?.path}");
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery({bool allowMultiple = false}) async {
    try {
      // final hasPermission = await _permissionService.requestStoragePermission();
      // if (!hasPermission) throw Exception('Storage permission denied');

      if (allowMultiple) {
        final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        return pickedFiles.isNotEmpty ? File(pickedFiles.first.path) : null;
      } else {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        Logger.logBasic("Picked file: ${pickedFile?.path}");
        return pickedFile != null ? File(pickedFile.path) : null;
      }
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImagesFromGallery() async {
    try {
      final hasPermission = await _permissionService.requestStoragePermission();
      if (!hasPermission) throw Exception('Storage permission denied');

      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      Logger.logBasic(
        "Picked files: ${pickedFiles.map((xFile) => xFile.path)}",
      );
      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick multiple images: $e');
    }
  }

  /// Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    try {
      final hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) throw Exception('Camera permission denied');

      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );

      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick video from camera: $e');
    }
  }

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final hasPermission = await _permissionService.requestStoragePermission();
      if (!hasPermission) throw Exception('Storage permission denied');

      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick video from gallery: $e');
    }
  }

  /// Pick any file
  Future<File?> pickFile({
    FileUploadType fileType = FileUploadType.any,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Request appropriate permission based on file type
      if (fileType == FileUploadType.audio) {
        final hasPermission = await _permissionService.requestAudioPermission();
        if (!hasPermission) throw Exception('Audio permission denied');
      } else {
        final hasPermission =
            await _permissionService.requestStoragePermission();
        if (!hasPermission) throw Exception('Storage permission denied');
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _getFilePickerType(fileType),
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: false,
        withReadStream: false,
      );

      return result != null && result.files.isNotEmpty
          ? File(result.files.first.path!)
          : null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Pick multiple files
  Future<List<File>> pickMultipleFiles({
    FileUploadType fileType = FileUploadType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Request appropriate permission based on file type
      if (fileType == FileUploadType.audio) {
        final hasPermission = await _permissionService.requestAudioPermission();
        if (!hasPermission) throw Exception('Audio permission denied');
      } else {
        final hasPermission =
            await _permissionService.requestStoragePermission();
        if (!hasPermission) throw Exception('Storage permission denied');
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _getFilePickerType(fileType),
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      return result != null
          ? result.paths.map((path) => File(path!)).toList()
          : [];
    } catch (e) {
      throw Exception('Failed to pick multiple files: $e');
    }
  }

  /// Validate file size and type
  bool validateFile(
    File file, {
    int? maxSizeInMB,
    int? maxSizeInBytes,
    List<String>? allowedExtensions,
    bool validateFileType = true,
  }) {
    try {
      // Check file size
      final fileSize = file.lengthSync();
      final maxSize =
          maxSizeInBytes ??
          (maxSizeInMB != null ? maxSizeInMB * 1024 * 1024 : null);

      if (maxSize != null && fileSize > maxSize) {
        throw Exception('File size exceeds limit');
      }

      // Check file extension if validation is enabled
      if (validateFileType && allowedExtensions != null) {
        final fileName = file.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        if (!allowedExtensions.contains(extension)) {
          throw Exception('File type .$extension is not allowed');
        }
      }

      return true;
    } catch (e) {
      throw Exception('File validation failed: $e');
    }
  }

  /// Get file picker type for different file types
  FileType _getFilePickerType(FileUploadType fileType) {
    switch (fileType) {
      case FileUploadType.image:
        return FileType.image;
      case FileUploadType.document:
        return FileType.custom;
      case FileUploadType.video:
        return FileType.video;
      case FileUploadType.audio:
        return FileType.audio;
      case FileUploadType.any:
        return FileType.any;
    }
  }

  // ============ Firebase Storage Upload Methods ============

  /// Upload a file to Firebase Storage
  ///
  /// [file] - The file to upload
  /// [storagePath] - The path in Firebase Storage
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  /// [compress] - Whether to compress the image before upload
  ///
  /// Returns the download URL
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    Function(double progress)? onProgress,
    bool compress = true,
  }) async {
    return _storageService.uploadFile(
      file: file,
      storagePath: storagePath,
      onProgress: onProgress,
      compress: compress,
    );
  }

  /// Upload a KYC document to Firebase Storage
  ///
  /// [file] - The document file to upload
  /// [userId] - The user's ID
  /// [documentType] - Type of document (government_id, selfie_with_id, proof_of_address)
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns the download URL
  Future<String> uploadKycDocument({
    required File file,
    required String userId,
    required String documentType,
    Function(double progress)? onProgress,
  }) async {
    return _storageService.uploadKycDocument(
      file: file,
      userId: userId,
      documentType: documentType,
      onProgress: onProgress,
    );
  }

  /// Pick an image and upload it as a KYC document
  ///
  /// [userId] - The user's ID
  /// [documentType] - Type of document (government_id, selfie_with_id, proof_of_address)
  /// [useCamera] - Whether to use camera (true) or gallery (false)
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns the download URL or null if user cancels
  Future<String?> pickAndUploadKycDocument({
    required String userId,
    required String documentType,
    bool useCamera = false,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Pick the image
      final File? pickedFile = useCamera
          ? await pickImageFromCamera()
          : await pickImageFromGallery();

      if (pickedFile == null) {
        return null; // User cancelled
      }

      // Validate file size (max 10MB)
      if (!validateFile(pickedFile, maxSizeInMB: 10)) {
        throw Exception('File size exceeds 10MB limit');
      }

      // Upload to Firebase
      final downloadUrl = await uploadKycDocument(
        file: pickedFile,
        userId: userId,
        documentType: documentType,
        onProgress: onProgress,
      );

      return downloadUrl;
    } catch (e) {
      Logger.logBasic('Failed to pick and upload KYC document: $e');
      rethrow;
    }
  }

  /// Delete a file from Firebase Storage
  ///
  /// [storagePath] - The path of the file to delete
  Future<void> deleteFile(String storagePath) async {
    return _storageService.deleteFile(storagePath);
  }

  /// Delete a file using its download URL
  ///
  /// [downloadUrl] - The download URL of the file
  Future<void> deleteFileByUrl(String downloadUrl) async {
    return _storageService.deleteFileByUrl(downloadUrl);
  }
}
