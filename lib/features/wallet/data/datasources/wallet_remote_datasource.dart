import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parcel_am/features/wallet/data/models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet(String userId);
  Future<void> createWallet(String userId);
  Future<void> updateBalance(String userId, double availableBalance, double pendingBalance);
  Stream<WalletModel> watchWallet(String userId);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String walletsCollection = 'wallets';

  WalletRemoteDataSourceImpl({required this.firestore});

  @override
  Future<WalletModel> getWallet(String userId) async {
    try {
      final doc = await firestore
          .collection(walletsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('Wallet not found for user: $userId');
      }

      return WalletModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch wallet: $e');
    }
  }

  @override
  Future<void> createWallet(String userId) async {
    try {
      final walletRef = firestore.collection(walletsCollection).doc(userId);
      
      final doc = await walletRef.get();
      if (doc.exists) {
        return;
      }

      await walletRef.set({
        'availableBalance': 0.0,
        'pendingBalance': 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  @override
  Future<void> updateBalance(
    String userId,
    double availableBalance,
    double pendingBalance,
  ) async {
    try {
      await firestore.collection(walletsCollection).doc(userId).update({
        'availableBalance': availableBalance,
        'pendingBalance': pendingBalance,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update wallet balance: $e');
    }
  }

  @override
  Stream<WalletModel> watchWallet(String userId) {
    return firestore
        .collection(walletsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Wallet not found for user: $userId');
      }
      return WalletModel.fromFirestore(doc);
    });
  }
}
