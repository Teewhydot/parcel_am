import 'package:equatable/equatable.dart';

/// Entity representing a single recovery code for TOTP 2FA
class RecoveryCodeEntity extends Equatable {
  /// The hashed recovery code (stored in database)
  /// Plain text code is only shown to user once during generation
  final String hash;

  /// Whether this recovery code has been used
  final bool isUsed;

  /// When this recovery code was used (if used)
  final DateTime? usedAt;

  const RecoveryCodeEntity({
    required this.hash,
    this.isUsed = false,
    this.usedAt,
  });

  RecoveryCodeEntity copyWith({
    String? hash,
    bool? isUsed,
    DateTime? usedAt,
  }) {
    return RecoveryCodeEntity(
      hash: hash ?? this.hash,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  @override
  List<Object?> get props => [hash, isUsed, usedAt];
}

/// Collection of recovery codes with metadata
class RecoveryCodesEntity extends Equatable {
  final List<RecoveryCodeEntity> codes;
  final DateTime generatedAt;

  const RecoveryCodesEntity({
    required this.codes,
    required this.generatedAt,
  });

  /// Count of remaining unused recovery codes
  int get remainingCount => codes.where((c) => !c.isUsed).length;

  /// Total number of recovery codes
  int get totalCount => codes.length;

  /// Check if all recovery codes have been used
  bool get isExhausted => remainingCount == 0;

  @override
  List<Object?> get props => [codes, generatedAt];
}
