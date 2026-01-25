class ServerException implements Exception {}

class NoInternetException implements Exception {}

class NotFoundException implements Exception {
  final String? message;
  const NotFoundException([this.message]);

  @override
  String toString() => message ?? 'Resource not found';
}

class UnknownException implements Exception {
  final String? errorMessage;
  UnknownException({this.errorMessage});
}

class TimeoutException implements Exception {}
