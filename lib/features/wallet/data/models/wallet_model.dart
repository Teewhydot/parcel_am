import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parcel_am/features/wallet/domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.userId,
    required super.availableBalance,
    required super.pendingBalance,
    super.lastUpdated,
  });

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      userId: doc.id,
      availableBalance: (data['availableBalance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory WalletModel.fromEntity(Wallet wallet) {
    return WalletModel(
      userId: wallet.userId,
      availableBalance: wallet.availableBalance,
      pendingBalance: wallet.pendingBalance,
      lastUpdated: wallet.lastUpdated,
    );
  }
}
