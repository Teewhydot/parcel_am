import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/funding_order_entity.dart';

/// Repository interface for funding order operations.
abstract class FundingOrderRepository {
  /// Watches the status of a funding order in real-time.
  ///
  /// [reference] The payment reference (without the 'F-' prefix)
  /// Returns a stream of [FundingOrderEntity] updates.
  Stream<Either<Failure, FundingOrderEntity>> watchFundingOrderStatus(
      String reference);

  /// Gets the current status of a funding order.
  ///
  /// [reference] The payment reference (without the 'F-' prefix)
  Future<Either<Failure, FundingOrderEntity>> getFundingOrderStatus(
      String reference);
}
