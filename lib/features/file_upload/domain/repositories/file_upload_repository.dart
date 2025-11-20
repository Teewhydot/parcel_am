import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/uploaded_file_entity.dart';

abstract class FileUploadRepository {
  Future<Either<Failure, UploadedFileEntity>> uploadFile({
    required String userId,
    required File file,
    String? fileName,
    String? folder,
    List<String>? tags,
    Map<String, dynamic>? customMetadata,
  });

  Future<Either<Failure, void>> deleteFile({required String fileId});

  Future<Either<Failure, String>> generateFileUrl({
    required String filePath,
    List<String>? transformations,
  });
}
