import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../errors/failure_mapper.dart';
import '../../errors/failures.dart';
import '../../utils/logger.dart';

/// Centralized error handler that converts exceptions to Either<Failure, T>
class ErrorHandler {
  static FailureMapper? _mapper;

  /// Initialize the ErrorHandler with a specific mapper
  static void init(FailureMapper mapper) {
    _mapper = mapper;
  }

  /// Handle any async operation and convert exceptions to failures
  static Future<Either<Failure, T>> handle<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      Logger.logBasic(
        'ErrorHandler.handle() starting${operationName != null ? " for $operationName" : ""}',
      );
      final result = await operation();
      if (operationName != null) {
        Logger.logSuccess('$operationName completed successfully');
      }
      return Right(result);
    } on SocketException catch (_) {
      final message = 'Please check your internet connection and try again';
      Logger.logError(
        'Network Error${operationName != null ? " in $operationName" : ""}: No internet connection',
      );
      return Left(NoInternetFailure(failureMessage: message));
    } on TimeoutException catch (_) {
      final message = 'Request timed out. Please try again';
      Logger.logError(
        'Timeout Error${operationName != null ? " in $operationName" : ""}: Operation timed out',
      );
      return Left(TimeoutFailure(failureMessage: message));
    } on FormatException catch (e) {
      final message = 'Invalid data format. Please try again';
      Logger.logError(
        'Format Error${operationName != null ? " in $operationName" : ""}: ${e.message}',
      );
      return Left(UnknownFailure(failureMessage: message));
    } catch (e, stackTrace) {
      // Try to map using the registered mapper
      final failure = _mapper?.map(e);
      if (failure != null) {
        Logger.logError(
          'Mapped Error${operationName != null ? " in $operationName" : ""}: ${failure.failureMessage}',
        );
        return Left(failure);
      }

      Logger.logError(
        'Catch-All Error${operationName != null ? " in $operationName" : ""}: Type=${e.runtimeType}, Error=$e',
      );
      Logger.logError('Stack trace: ${stackTrace.toString()}');

      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  /// Handle stream operations and convert exceptions to Either stream
  static Stream<Either<Failure, T>> handleStream<T>(
    Stream<T> Function() streamOperation, {
    String? operationName,
  }) {
    final controller = StreamController<Either<Failure, T>>();

    try {
      final stream = streamOperation();

      stream.listen(
        (data) {
          if (operationName != null) {
            Logger.logSuccess('$operationName: Data received');
          }
          controller.add(Right(data));
        },
        onError: (error, stackTrace) {
          // Try to map using the registered mapper
          final failure = _mapper?.map(error);
          if (failure != null) {
             Logger.logError(
              'Stream Mapped Error${operationName != null ? " in $operationName" : ""}: ${failure.failureMessage}',
            );
            controller.add(Left(failure));
            return;
          }

          if (error is SocketException) {
            final message =
                'Please check your internet connection and try again';
            Logger.logError(
              'Stream Network Error${operationName != null ? " in $operationName" : ""}: No internet connection',
            );
            controller.add(Left(NoInternetFailure(failureMessage: message)));
          } else if (error is TimeoutException) {
            final message = 'Stream timed out. Please try again';
            Logger.logError(
              'Stream Timeout Error${operationName != null ? " in $operationName" : ""}: Operation timed out',
            );
            controller.add(Left(TimeoutFailure(failureMessage: message)));
          } else if (error is FormatException) {
            final message = 'Invalid data format in stream';
            Logger.logError(
              'Stream Format Error${operationName != null ? " in $operationName" : ""}: ${error.message}',
            );
            controller.add(Left(UnknownFailure(failureMessage: message)));
          } else {
            final message = 'Stream error occurred. Please try again';
            Logger.logError(
              'Stream Unknown Error${operationName != null ? " in $operationName" : ""}: $error',
            );
            controller.add(Left(UnknownFailure(failureMessage: message)));
          }
        },
        onDone: () {
          if (operationName != null) {
            Logger.logBasic('$operationName: Stream completed');
          }
          controller.close();
        },
        cancelOnError: false, // Continue stream even after errors
      );
    } catch (e) {
      final message = 'Failed to initialize stream';
      Logger.logError(
        'Stream Initialization Error${operationName != null ? " in $operationName" : ""}: $e',
      );
      controller.add(Left(UnknownFailure(failureMessage: message)));
      controller.close();
    }

    return controller.stream;
  }
}

