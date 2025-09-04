import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);
}

class ServerFailure extends Failure {
  const ServerFailure();

  @override
  List<Object> get props => [];
}

class CacheFailure extends Failure {
  const CacheFailure();

  @override
  List<Object> get props => [];
}

class NetworkFailure extends Failure {
  const NetworkFailure();

  @override
  List<Object> get props => [];
}