import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/file_upload_repository.dart';
import '../entities/uploaded_file_entity.dart';

class FileUploadUseCase {
  final FileUploadRepository _repository;

  FileUploadUseCase({FileUploadRepository? repository})
      : _repository = repository ?? GetIt.instance<FileUploadRepository>();
  
  Future<Either<Failure, void>> deleteFile({
    required String userId,
    required String fileId,
  }) async {
    return await _repository.deleteFile(fileId: fileId);
  }

  Future<Either<Failure, String>> generateFileUrl({
    required String filePath,
    List<String>? transformations,
  }) {
    return _repository.generateFileUrl(
      filePath: filePath,
      transformations: transformations,
    );
  }

  Future<Either<Failure, UploadedFileEntity>> uploadFile({
    required String userId,
    required File file,
    required String folder,
  }) async {
    return await _repository.uploadFile(
      userId: userId, // Replace with actual user ID retrieval logic
      file: file,
      folder: folder,
    );
  }
}
