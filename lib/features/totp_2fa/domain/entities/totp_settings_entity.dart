import 'package:equatable/equatable.dart';

/// Entity representing user's TOTP 2FA settings
class TotpSettingsEntity extends Equatable {
  final String id;
  final String userId;
  final bool isEnabled;
  final DateTime? enabledAt;
  final DateTime? lastVerifiedAt;
  final int failedAttempts;
  final DateTime? lockedUntil;

  const TotpSettingsEntity({
    required this.id,
    required this.userId,
    required this.isEnabled,
    this.enabledAt,
    this.lastVerifiedAt,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  /// Check if the account is currently locked due to too many failed attempts
  bool get isLocked =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  /// Get remaining lock time in minutes
  int get remainingLockMinutes {
    if (!isLocked) return 0;
    return lockedUntil!.difference(DateTime.now()).inMinutes;
  }

  TotpSettingsEntity copyWith({
    String? id,
    String? userId,
    bool? isEnabled,
    DateTime? enabledAt,
    DateTime? lastVerifiedAt,
    int? failedAttempts,
    DateTime? lockedUntil,
  }) {
    return TotpSettingsEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isEnabled: isEnabled ?? this.isEnabled,
      enabledAt: enabledAt ?? this.enabledAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        isEnabled,
        enabledAt,
        lastVerifiedAt,
        failedAttempts,
        lockedUntil,
      ];
}
