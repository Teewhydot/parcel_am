import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../../core/constants/env.dart';
import '../../../../core/data/datasources/authenticated_remote_data_source.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../models/withdrawal_order_model.dart';

abstract class WithdrawalRemoteDataSource {
  /// Generate unique withdrawal reference
  String generateWithdrawalReference();

  /// Initiate withdrawal via Firebase Function
  Future<WithdrawalOrderModel> initiateWithdrawal({
    required String userId,
    required double amount,
    required String recipientCode,
    required String withdrawalReference,
    required String bankAccountId,
  });

  /// Get withdrawal order by ID
  Future<WithdrawalOrderModel> getWithdrawalOrder(String withdrawalId);

  /// Watch withdrawal order for real-time updates
  Stream<WithdrawalOrderModel> watchWithdrawalOrder(String withdrawalId);

  /// Get user's withdrawal history
  Future<List<WithdrawalOrderModel>> getWithdrawalHistory({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  });
}

class WithdrawalRemoteDataSourceImpl
    with AuthenticatedRemoteDataSourceMixin
    implements WithdrawalRemoteDataSource {
  final FirebaseFirestore firestore;
  @override
  final FirebaseAuth auth;
  @override
  final ConnectivityService connectivityService;
  final String? baseUrl = Env.firebaseCloudFunctionsUrl;
  final _uuid = const Uuid();

  WithdrawalRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
    required this.connectivityService,
  });

  @override
  String generateWithdrawalReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4().substring(0, 8); // Use first 8 chars of UUID
    return 'WTH-$timestamp-$uuid';
  }

  @override
  Future<WithdrawalOrderModel> initiateWithdrawal({
    required String userId,
    required double amount,
    required String recipientCode,
    required String withdrawalReference,
    required String bankAccountId,
  }) async {
    try {
      await validateConnectivity();

      Logger.logBasic('Initiating withdrawal: $withdrawalReference for amount: NGN $amount');
      final idToken = await getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/initiateWithdrawal'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'recipientCode': recipientCode,
          'withdrawalReference': withdrawalReference,
          'bankAccountId': bankAccountId,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout. Please check withdrawal status.');
        },
      );

      Logger.logBasic('Withdrawal response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Logger.logSuccess('Withdrawal initiated successfully: $withdrawalReference');

        // Fetch the created withdrawal order from Firestore
        final withdrawalDoc = await firestore
            .collection('withdrawal_orders')
            .doc(withdrawalReference)
            .get();

        if (withdrawalDoc.exists) {
          return WithdrawalOrderModel.fromFirestore(withdrawalDoc);
        } else {
          throw Exception('Withdrawal order not found after creation');
        }
      } else {
        final error = json.decode(response.body);
        final errorMessage = error['error'] ?? error['message'] ?? 'Withdrawal failed';
        Logger.logError('Withdrawal failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      Logger.logError('Error initiating withdrawal: $e');
      if (e is NoInternetException) rethrow;
      rethrow;
    }
  }

  @override
  Future<WithdrawalOrderModel> getWithdrawalOrder(String withdrawalId) async {
    try {
      final doc = await firestore
          .collection('withdrawal_orders')
          .doc(withdrawalId)
          .get();

      if (!doc.exists) {
        throw Exception('Withdrawal order not found');
      }

      return WithdrawalOrderModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      Logger.logError('Firestore error fetching withdrawal order: $e');
      throw ServerException();
    } catch (e) {
      Logger.logError('Error fetching withdrawal order: $e');
      rethrow;
    }
  }

  @override
  Stream<WithdrawalOrderModel> watchWithdrawalOrder(String withdrawalId) {
    return firestore
        .collection('withdrawal_orders')
        .doc(withdrawalId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Withdrawal order not found');
      }
      return WithdrawalOrderModel.fromFirestore(doc);
    });
  }

  @override
  Future<List<WithdrawalOrderModel>> getWithdrawalHistory({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = firestore
          .collection('withdrawal_orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => WithdrawalOrderModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      Logger.logError('Firestore error fetching withdrawal history: $e');
      throw ServerException();
    } catch (e) {
      Logger.logError('Error fetching withdrawal history: $e');
      throw ServerException();
    }
  }
}
