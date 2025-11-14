import '../../../domain/entities/escrow_entity.dart';

class EscrowData {
  final EscrowEntity? currentEscrow;
  final List<EscrowEntity> userEscrows;

  const EscrowData({
    this.currentEscrow,
    this.userEscrows = const [],
  });

  EscrowData copyWith({
    EscrowEntity? currentEscrow,
    List<EscrowEntity>? userEscrows,
  }) {
    return EscrowData(
      currentEscrow: currentEscrow ?? this.currentEscrow,
      userEscrows: userEscrows ?? this.userEscrows,
    );
  }
}
