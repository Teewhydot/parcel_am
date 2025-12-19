import 'package:equatable/equatable.dart';

/// Base class for all passkey events
abstract class PasskeyEvent extends Equatable {
  const PasskeyEvent();

  @override
  List<Object?> get props => [];
}

/// Check if passkeys are supported on this device
class PasskeyCheckSupport extends PasskeyEvent {
  const PasskeyCheckSupport();
}

/// Sign up with a new passkey
class PasskeySignUpRequested extends PasskeyEvent {
  final String email;

  const PasskeySignUpRequested({required this.email});

  @override
  List<Object> get props => [email];
}

/// Sign in with existing passkey
class PasskeySignInRequested extends PasskeyEvent {
  const PasskeySignInRequested();
}

/// Append a passkey to current user account
class PasskeyAppendRequested extends PasskeyEvent {
  const PasskeyAppendRequested();
}

/// Load all passkeys for current user
class PasskeyListRequested extends PasskeyEvent {
  const PasskeyListRequested();
}

/// Remove a passkey
class PasskeyRemoveRequested extends PasskeyEvent {
  final String credentialId;

  const PasskeyRemoveRequested({required this.credentialId});

  @override
  List<Object> get props => [credentialId];
}

/// Sign out from passkey session
class PasskeySignOutRequested extends PasskeyEvent {
  const PasskeySignOutRequested();
}

/// Reset passkey state
class PasskeyStateReset extends PasskeyEvent {
  const PasskeyStateReset();
}
