import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/uploaded_file_entity.dart';
import '../../domain/repositories/file_upload_repository.dart';
import '../remote/data_sources/file_upload.dart';

class FileUploadRepositoryImpl implements FileUploadRepository {
  final FileUploadDataSource _remoteDataSource;

  FileUploadRepositoryImpl({FileUploadDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<FileUploadDataSource>();

  @override
  Future<Either<Failure, UploadedFileEntity>> uploadFile({
    required String userId,
    required File file,
    String? fileName,
    required String folder,
    List<String>? tags,
    Map<String, dynamic>? customMetadata,
  }) async {
    return ErrorHandler.handle(
      () async => await _remoteDataSource.uploadFile(userId: userId, file: file,folderPath: folder),
      operationName: "File Upload",
    );
  }

  @override
  Future<Either<Failure, void>> deleteFile({required String fileId}) async {
    return ErrorHandler.handle(
      () async => await _remoteDataSource.deleteFile(fileId: fileId),
      operationName: "File Deletion",
    );
  }

  @override
  Future<Either<Failure, String>> generateFileUrl({
    required String filePath,
    List<String>? transformations,
  }) async {
    return ErrorHandler.handle(
      () async => await _remoteDataSource.generateUrl(
        filePath: filePath,
        transformations: transformations,
      ),
      operationName: "Generate File URL",
    );
  }
}
