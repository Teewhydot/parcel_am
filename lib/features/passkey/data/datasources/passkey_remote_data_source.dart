import 'dart:async';
import 'package:corbado_auth/corbado_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/passkey_model.dart';
import '../models/passkey_auth_result_model.dart';
import '../../../../core/errors/failures.dart';

/// Abstract interface for passkey remote data source
abstract class PasskeyRemoteDataSource {
  /// Initialize the Corbado SDK
  Future<void> initialize(String projectId);

  /// Check if passkeys are supported on this device
  Future<bool> isPasskeySupported();

  /// Sign up a new user with passkey
  Future<PasskeyAuthResultModel> signUpWithPasskey(String email);

  /// Sign in with passkey
  Future<PasskeyAuthResultModel> signInWithPasskey();

  /// Append a new passkey to the current user
  Future<PasskeyModel> appendPasskey();

  /// Get all passkeys for the current user
  Future<List<PasskeyModel>> getPasskeys();

  /// Remove a passkey
  Future<void> removePasskey(String credentialId);

  /// Check if user has registered passkeys
  Future<bool> hasRegisteredPasskeys();

  /// Sign out
  Future<void> signOut();

  /// Get current user
  Future<PasskeyAuthResultModel?> getCurrentUser();

  /// Stream of auth state changes
  Stream<PasskeyAuthResultModel?> get authStateChanges;
}

/// Implementation of PasskeyRemoteDataSource using Corbado SDK
class CorbadoPasskeyDataSourceImpl implements PasskeyRemoteDataSource {
  CorbadoAuth? _corbadoAuth;
  bool _isInitialized = false;
  final StreamController<PasskeyAuthResultModel?> _authStateController =
      StreamController<PasskeyAuthResultModel?>.broadcast();

  CorbadoPasskeyDataSourceImpl();

  @override
  Future<void> initialize(String projectId) async {
    if (_isInitialized) return;

    _corbadoAuth = CorbadoAuth();
    await _corbadoAuth!.init(projectId: projectId);

    // Listen to Corbado auth state changes
    _corbadoAuth!.authStateChanges.listen((authState) async {
      if (authState == AuthState.SignedIn) {
        final user = await _corbadoAuth!.currentUser;
        if (user != null) {
          _authStateController.add(PasskeyAuthResultModel(
            corbadoUserId: user.decoded.sub,
            email: user.email ?? '',
            displayName: user.username,
          ));
        }
      } else {
        _authStateController.add(null);
      }
    });

    _isInitialized = true;
  }

  CorbadoAuth get _auth {
    if (_corbadoAuth == null || !_isInitialized) {
      throw const PasskeyFailure(
        failureMessage: 'Corbado SDK not initialized. Call initialize() first.',
      );
    }
    return _corbadoAuth!;
  }

  @override
  Future<bool> isPasskeySupported() async {
    try {
      // Check platform support
      if (kIsWeb) {
        // Web platform - WebAuthn is widely supported in modern browsers
        return true;
      }

      // Mobile platforms - passkeys supported on iOS 16+ and Android 9+
      // The Corbado SDK handles platform detection internally
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<PasskeyAuthResultModel> signUpWithPasskey(String email) async {
    // Note: Corbado SDK uses a different flow for signup
    // The actual passkey creation happens through the Corbado UI flow
    // For now, we'll throw an error as signup requires the Corbado UI component
    throw const PasskeyRegistrationFailure(
      failureMessage: 'Passkey signup requires Corbado UI flow. Please use email/password signup first, then add a passkey.',
    );
  }

  @override
  Future<PasskeyAuthResultModel> signInWithPasskey() async {
    try {
      // Note: Corbado SDK v2.x uses a different authentication flow
      // that typically involves UI components
      // For headless passkey login, we check if user is already authenticated
      final user = await _auth.currentUser;

      if (user != null) {
        return PasskeyAuthResultModel(
          corbadoUserId: user.decoded.sub,
          email: user.email ?? '',
          displayName: user.username,
          isNewUser: false,
        );
      }

      throw const PasskeyAuthenticationFailure(
        failureMessage: 'Passkey authentication requires Corbado UI flow',
      );
    } catch (e) {
      if (e is PasskeyFailure) rethrow;
      throw PasskeyAuthenticationFailure(
        failureMessage: 'Passkey signin failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<PasskeyModel> appendPasskey() async {
    try {
      await _auth.appendPasskey();

      // Get the newly added passkey
      final passkeys = await getPasskeys();
      if (passkeys.isEmpty) {
        throw const PasskeyRegistrationFailure(
          failureMessage: 'Failed to retrieve appended passkey',
        );
      }

      // Return the most recently created passkey
      return passkeys.reduce((a, b) =>
        a.createdAt.isAfter(b.createdAt) ? a : b
      );
    } catch (e) {
      if (e is PasskeyFailure) rethrow;

      // Check for duplicate passkey error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('exclude') || errorMessage.contains('already')) {
        throw const PasskeyAlreadyExistsFailure();
      }

      throw PasskeyRegistrationFailure(
        failureMessage: 'Failed to append passkey: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<PasskeyModel>> getPasskeys() async {
    try {
      // Listen to passkeys changes and get the first emission
      final passkeys = await _auth.passkeysChanges.first;
      final user = await _auth.currentUser;

      return passkeys.map((p) => PasskeyModel(
        id: p.id,
        credentialId: p.id,
        userId: user?.decoded.sub ?? '',
        deviceName: _formatDeviceName(p.sourceOS, p.sourceBrowser),
        createdAt: _parseCreatedDate(p.created),
        lastUsedAt: _parseCreatedDate(p.created), // Use created as fallback
        isActive: true, // Assume active if returned from SDK
      )).toList();
    } catch (e) {
      throw PasskeyFailure(
        failureMessage: 'Failed to get passkeys: ${e.toString()}',
      );
    }
  }

  /// Format device name from OS and browser info
  String _formatDeviceName(String sourceOS, String sourceBrowser) {
    if (sourceOS.isNotEmpty && sourceBrowser.isNotEmpty) {
      return '$sourceOS - $sourceBrowser';
    } else if (sourceOS.isNotEmpty) {
      return sourceOS;
    } else if (sourceBrowser.isNotEmpty) {
      return sourceBrowser;
    }
    return 'Unknown Device';
  }

  /// Parse created date string to DateTime
  DateTime _parseCreatedDate(String created) {
    try {
      return DateTime.parse(created);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Future<void> removePasskey(String credentialId) async {
    try {
      await _auth.deletePasskey(credentialID: credentialId);
    } catch (e) {
      throw PasskeyFailure(
        failureMessage: 'Failed to remove passkey: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> hasRegisteredPasskeys() async {
    try {
      final passkeys = await getPasskeys();
      return passkeys.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw PasskeyFailure(
        failureMessage: 'Failed to sign out: ${e.toString()}',
      );
    }
  }

  @override
  Future<PasskeyAuthResultModel?> getCurrentUser() async {
    final user = await _auth.currentUser;
    if (user == null) return null;

    return PasskeyAuthResultModel(
      corbadoUserId: user.decoded.sub,
      email: user.email ?? '',
      displayName: user.username,
    );
  }

  @override
  Stream<PasskeyAuthResultModel?> get authStateChanges =>
      _authStateController.stream;

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
