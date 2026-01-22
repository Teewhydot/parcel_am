import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/funding_order_entity.dart';
import '../../domain/repositories/funding_order_repository.dart';
import '../datasources/funding_order_remote_data_source.dart';

/// Implementation of [FundingOrderRepository].
class FundingOrderRepositoryImpl implements FundingOrderRepository {
  final FundingOrderRemoteDataSource _remoteDataSource;

  FundingOrderRepositoryImpl({FundingOrderRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<FundingOrderRemoteDataSource>();

  @override
  Stream<Either<Failure, FundingOrderEntity>> watchFundingOrderStatus(
      String reference) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchFundingOrderStatus(reference),
    );
  }

  @override
  Future<Either<Failure, FundingOrderEntity>> getFundingOrderStatus(
      String reference) {
    return ErrorHandler.handle(
      () => _remoteDataSource.getFundingOrderStatus(reference),
    );
  }
}
