class WalletData {
  final double availableBalance;
  final double pendingBalance;
  final List<EscrowTransaction> escrowTransactions;
  final String currency;
  final WalletInfo? wallet;

  const WalletData({
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.escrowTransactions = const [],
    this.currency = 'NGN',
    this.wallet,
  });

  double get balance => availableBalance + pendingBalance;
  double get escrowBalance => pendingBalance;

  WalletData copyWith({
    double? availableBalance,
    double? pendingBalance,
    List<EscrowTransaction>? escrowTransactions,
    String? currency,
    WalletInfo? wallet,
  }) {
    return WalletData(
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      escrowTransactions: escrowTransactions ?? this.escrowTransactions,
      currency: currency ?? this.currency,
      wallet: wallet ?? this.wallet,
    );
  }
}

class WalletInfo {
  final List<Transaction> recentTransactions;

  const WalletInfo({
    this.recentTransactions = const [],
  });
}

class EscrowTransaction {
  final String transactionId;
  final String packageId;
  final double amount;
  final DateTime heldAt;
  final EscrowStatus status;

  const EscrowTransaction({
    required this.transactionId,
    required this.packageId,
    required this.amount,
    required this.heldAt,
    required this.status,
  });

  EscrowTransaction copyWith({
    String? transactionId,
    String? packageId,
    double? amount,
    DateTime? heldAt,
    EscrowStatus? status,
  }) {
    return EscrowTransaction(
      transactionId: transactionId ?? this.transactionId,
      packageId: packageId ?? this.packageId,
      amount: amount ?? this.amount,
      heldAt: heldAt ?? this.heldAt,
      status: status ?? this.status,
    );
  }
}

enum EscrowStatus {
  held,
  released,
  cancelled,
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String description;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });
}
