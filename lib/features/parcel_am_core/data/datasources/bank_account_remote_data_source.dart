import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/env.dart';
import '../../../../core/data/datasources/authenticated_remote_data_source.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../models/bank_info_model.dart';
import '../models/user_bank_account_model.dart';

abstract class BankAccountRemoteDataSource {
  /// Get list of Nigerian banks from cache or Paystack API
  Future<List<BankInfoModel>> getBankList();

  /// Resolve bank account details using Paystack API
  Future<Map<String, dynamic>> resolveBankAccount({
    required String accountNumber,
    required String bankCode,
  });

  /// Create transfer recipient on Paystack
  Future<String> createTransferRecipient({
    required String accountNumber,
    required String accountName,
    required String bankCode,
  });

  /// Save verified bank account to Firestore
  Future<UserBankAccountModel> saveUserBankAccount({
    required String userId,
    required String accountNumber,
    required String accountName,
    required String bankCode,
    required String bankName,
    required String recipientCode,
  });

  /// Get user's saved bank accounts
  Future<List<UserBankAccountModel>> getUserBankAccounts(String userId);

  /// Delete user bank account (soft delete)
  Future<void> deleteUserBankAccount({
    required String userId,
    required String accountId,
  });
}

class BankAccountRemoteDataSourceImpl
    with AuthenticatedRemoteDataSourceMixin
    implements BankAccountRemoteDataSource {
  final FirebaseFirestore firestore;
  @override
  final FirebaseAuth auth;
  @override
  final ConnectivityService connectivityService;
  final String? baseUrl = Env.firebaseCloudFunctionsUrl;

  // Cache for bank list (refresh daily)
  List<BankInfoModel>? _cachedBankList;
  DateTime? _cacheTimestamp;

  BankAccountRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
    required this.connectivityService,
  });

  @override
  Future<List<BankInfoModel>> getBankList() async {
    try {
      // Check if cache is valid (less than 24 hours old)
      if (_cachedBankList != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!).inHours < 24) {
        Logger.logBasic('Returning cached bank list');
        return _cachedBankList!;
      }

      // Fetch bank list from Firestore 'banks' collection
      Logger.logBasic('Fetching bank list from Firestore');
      final querySnapshot = await firestore
          .collection('banks')
          .get();

      // Sort by name in memory
      final banksList = querySnapshot.docs
          .map((doc) => BankInfoModel.fromFirestore(doc.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (banksList.isEmpty) {
        Logger.logBasic('No banks found in Firestore');
      }

      _cachedBankList = banksList;
      _cacheTimestamp = DateTime.now();

      Logger.logSuccess('Bank list loaded from Firestore: ${banksList.length} banks');
      return banksList;
    } on FirebaseException catch (e) {
      Logger.logError('Firestore error fetching bank list: $e');
      throw ServerException();
    } catch (e) {
      Logger.logError('Error fetching bank list: $e');
      throw ServerException();
    }
  }

  @override
  Future<Map<String, dynamic>> resolveBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      await validateConnectivity();

      Logger.logBasic('Resolving bank account: $accountNumber with bank code: $bankCode');
      final idToken = await getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/resolveBankAccount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'accountNumber': accountNumber,
          'bankCode': bankCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Logger.logSuccess('Bank account resolved: ${data['accountName']}');
        return {
          'accountName': data['accountName'],
          'accountNumber': accountNumber,
          'bankCode': bankCode,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception('Account verification failed: ${error['error'] ?? error['message']}');
      }
    } catch (e) {
      Logger.logError('Error resolving bank account: $e');
      if (e is NoInternetException) rethrow;
      rethrow;
    }
  }

  @override
  Future<String> createTransferRecipient({
    required String accountNumber,
    required String accountName,
    required String bankCode,
  }) async {
    try {
      await validateConnectivity();

      Logger.logBasic('Creating transfer recipient for account: $accountNumber');
      final idToken = await getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/createTransferRecipient'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'accountNumber': accountNumber,
          'accountName': accountName,
          'bankCode': bankCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipientCode = data['recipientCode'] as String;
        Logger.logSuccess('Transfer recipient created: $recipientCode');
        return recipientCode;
      } else {
        final error = json.decode(response.body);
        throw Exception('Failed to create recipient: ${error['error'] ?? error['message']}');
      }
    } catch (e) {
      Logger.logError('Error creating transfer recipient: $e');
      if (e is NoInternetException) rethrow;
      rethrow;
    }
  }

  @override
  Future<UserBankAccountModel> saveUserBankAccount({
    required String userId,
    required String accountNumber,
    required String accountName,
    required String bankCode,
    required String bankName,
    required String recipientCode,
  }) async {
    try {
      await validateConnectivity();

      // Check if user already has 5 bank accounts
      final existingAccounts = await getUserBankAccounts(userId);
      if (existingAccounts.length >= 5) {
        throw Exception('Maximum of 5 bank accounts allowed');
      }

      // Create new bank account document
      final accountRef = firestore
          .collection('users')
          .doc(userId)
          .collection('user_bank_accounts')
          .doc();

      final accountData = {
        'id': accountRef.id,
        'userId': userId,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'bankCode': bankCode,
        'bankName': bankName,
        'recipientCode': recipientCode,
        'verified': true,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await accountRef.set(accountData);

      final savedDoc = await accountRef.get();
      Logger.logSuccess('Bank account saved successfully: $accountName');
      return UserBankAccountModel.fromFirestore(savedDoc);
    } on FirebaseException catch (e) {
      Logger.logError('Firestore error saving bank account: $e');
      throw ServerException();
    } catch (e) {
      Logger.logError('Error saving bank account: $e');
      if (e is NoInternetException) rethrow;
      rethrow;
    }
  }

  @override
  Future<List<UserBankAccountModel>> getUserBankAccounts(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('user_bank_accounts')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => UserBankAccountModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      Logger.logError('Firestore error fetching bank accounts: $e');
      throw ServerException();
    } catch (e) {
      Logger.logError('Error fetching bank accounts: $e');
      throw ServerException();
    }
  }

  @override
  Future<void> deleteUserBankAccount({
    required String userId,
    required String accountId,
  }) async {
    try {
      await validateConnectivity();

      // Soft delete - set active to false
      await firestore
          .collection('users')
          .doc(userId)
          .collection('user_bank_accounts')
          .doc(accountId)
          .update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.logSuccess('Bank account deleted: $accountId');
    } on FirebaseException catch (e) {
      Logger.logError('Firestore error deleting bank account: $e');
      throw ServerException();
    } catch (e) {
      Logger.logError('Error deleting bank account: $e');
      if (e is NoInternetException) rethrow;
      rethrow;
    }
  }
}
