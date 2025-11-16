import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/parcel_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../../domain/exceptions/wallet_exceptions.dart';
import '../models/dashboard_metrics_model.dart';
import '../models/parcel_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'wallet_remote_data_source.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardMetricsModel> fetchDashboardMetrics(String userId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl({
    required this.firestore,
    required this.walletRemoteDataSource,
  });

  final FirebaseFirestore firestore;
  final WalletRemoteDataSource walletRemoteDataSource;

  @override
  Future<DashboardMetricsModel> fetchDashboardMetrics(String userId) async {
    try {
      final snapshots = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        firestore
            .collection('parcels')
            .where('sender.userId', isEqualTo: userId)
            .get(),
        firestore
            .collection('parcels')
            .where('travelerId', isEqualTo: userId)
            .get(),
        firestore
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .get(),
      ]);

      final sentSnapshot = snapshots[0];
      final carriedSnapshot = snapshots[1];
      final transactionsSnapshot = snapshots[2];

      final sentParcels = sentSnapshot.docs
          .map((doc) => ParcelModel.fromFirestore(doc).toEntity())
          .toList();
      final carriedParcels = carriedSnapshot.docs
          .map((doc) => ParcelModel.fromFirestore(doc).toEntity())
          .toList();
      final transactions = transactionsSnapshot.docs
          .map(TransactionModel.fromFirestore)
          .toList();

      final totalPackages = sentParcels.length;
      final activePackages = sentParcels
          .where((parcel) =>
              parcel.status == ParcelStatus.created ||
              parcel.status == ParcelStatus.paid ||
              parcel.status == ParcelStatus.inTransit)
          .length;
      final deliveredPackages =
          sentParcels.where((parcel) => parcel.status.isCompleted).length;
      final cancelledPackages =
          sentParcels.where((parcel) => parcel.status.isCancelled).length;
      final packagesCarried = carriedParcels.length;

      double successRate = 0;
      if (totalPackages > 0) {
        successRate = deliveredPackages / totalPackages;
      }

      final deliveryDurations = sentParcels
          .where((parcel) => parcel.status == ParcelStatus.delivered)
          .map(_mapParcelToDeliveryDuration)
          .whereType<Duration>()
          .toList();

      Duration? averageDeliveryTime;
      if (deliveryDurations.isNotEmpty) {
        final totalMilliseconds = deliveryDurations
            .map((duration) => duration.inMilliseconds)
            .reduce((value, element) => value + element);
        averageDeliveryTime = Duration(
          milliseconds: (totalMilliseconds / deliveryDurations.length).round(),
        );
      }

      final totalEarnings = transactions
          .where((transaction) =>
              transaction.type == TransactionType.earning &&
              transaction.status == TransactionStatus.completed)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);

      final pendingEarnings = transactions
          .where((transaction) =>
              transaction.type == TransactionType.earning &&
              transaction.status == TransactionStatus.pending)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);

      WalletModel? walletModel;
      try {
        walletModel = await walletRemoteDataSource.getWallet(userId);
      } catch (_) {
        walletModel = null;
      }

      final currency = walletModel?.currency ?? 'NGN';

      return DashboardMetricsModel(
        totalPackages: totalPackages,
        activePackages: activePackages,
        deliveredPackages: deliveredPackages,
        cancelledPackages: cancelledPackages,
        packagesCarried: packagesCarried,
        totalEarnings: totalEarnings,
        pendingEarnings: pendingEarnings,
        successRate: successRate,
        averageDeliveryTime: averageDeliveryTime,
        currency: currency,
      );
    } on FirebaseException {
      throw ServerException();
    } catch (_) {
      throw ServerException();
    }
  }

  Duration? _mapParcelToDeliveryDuration(ParcelEntity parcel) {
    DateTime? endTime;
    if (parcel.route.actualDeliveryDate != null) {
      endTime = DateTime.tryParse(parcel.route.actualDeliveryDate!);
    }
    endTime ??= parcel.updatedAt;
    if (endTime == null) {
      return null;
    }

    final startTime = parcel.createdAt;
    if (endTime.isBefore(startTime)) {
      return null;
    }

    return endTime.difference(startTime);
  }
}
