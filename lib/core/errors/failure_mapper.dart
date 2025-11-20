import 'failures.dart';

/// Interface for mapping exceptions to Failures
abstract class FailureMapper {
  /// Maps an error object to a Failure, or returns null if not handled
  Failure? map(Object error);
}
