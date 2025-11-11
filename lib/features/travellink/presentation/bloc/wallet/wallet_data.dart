class WalletData {
  final double availableBalance;
  final double pendingBalance;
  final List<EscrowTransaction> escrowTransactions;

  const WalletData({
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.escrowTransactions = const [],
  });

  WalletData copyWith({
    double? availableBalance,
    double? pendingBalance,
    List<EscrowTransaction>? escrowTransactions,
  }) {
    return WalletData(
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      escrowTransactions: escrowTransactions ?? this.escrowTransactions,
    );
  }
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
