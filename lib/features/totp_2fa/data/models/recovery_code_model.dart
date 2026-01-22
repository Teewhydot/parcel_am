import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/recovery_code_entity.dart';

/// Data model for a single recovery code with Firestore serialization
class RecoveryCodeModel extends RecoveryCodeEntity {
  const RecoveryCodeModel({
    required super.hash,
    super.isUsed,
    super.usedAt,
  });

  /// Create model from Firestore document data
  factory RecoveryCodeModel.fromJson(Map<String, dynamic> json) {
    return RecoveryCodeModel(
      hash: json['hash'] as String? ?? '',
      isUsed: json['isUsed'] as bool? ?? false,
      usedAt: _parseTimestamp(json['usedAt']),
    );
  }

  /// Convert model to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  /// Create model from entity
  factory RecoveryCodeModel.fromEntity(RecoveryCodeEntity entity) {
    return RecoveryCodeModel(
      hash: entity.hash,
      isUsed: entity.isUsed,
      usedAt: entity.usedAt,
    );
  }

  /// Convert to entity
  RecoveryCodeEntity toEntity() {
    return RecoveryCodeEntity(
      hash: hash,
      isUsed: isUsed,
      usedAt: usedAt,
    );
  }

  /// Helper to parse Firestore Timestamp or DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  RecoveryCodeModel copyWith({
    String? hash,
    bool? isUsed,
    DateTime? usedAt,
  }) {
    return RecoveryCodeModel(
      hash: hash ?? this.hash,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}

/// Data model for collection of recovery codes with Firestore serialization
class RecoveryCodesModel extends RecoveryCodesEntity {
  const RecoveryCodesModel({
    required super.codes,
    required super.generatedAt,
  });

  /// Create model from Firestore document data
  factory RecoveryCodesModel.fromJson(Map<String, dynamic> json) {
    final codesList = (json['codes'] as List<dynamic>?)
            ?.map((e) => RecoveryCodeModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    DateTime? generatedAt;
    final genAt = json['generatedAt'];
    if (genAt is Timestamp) {
      generatedAt = genAt.toDate();
    } else if (genAt is DateTime) {
      generatedAt = genAt;
    }

    return RecoveryCodesModel(
      codes: codesList,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }

  /// Convert model to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'codes': codes
          .map((c) => RecoveryCodeModel.fromEntity(c).toJson())
          .toList(),
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  /// Create model from entity
  factory RecoveryCodesModel.fromEntity(RecoveryCodesEntity entity) {
    return RecoveryCodesModel(
      codes: entity.codes,
      generatedAt: entity.generatedAt,
    );
  }

  /// Convert to entity
  RecoveryCodesEntity toEntity() {
    return RecoveryCodesEntity(
      codes: codes,
      generatedAt: generatedAt,
    );
  }
}
