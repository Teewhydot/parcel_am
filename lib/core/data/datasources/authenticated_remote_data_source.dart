import 'package:firebase_auth/firebase_auth.dart';
import '../../services/connectivity_service.dart';
import '../../../features/parcel_am_core/domain/exceptions/custom_exceptions.dart';

/// Mixin providing common authentication and connectivity methods for remote data sources.
///
/// This mixin extracts duplicated code patterns from multiple data sources:
/// - Connectivity validation
/// - Firebase Auth token retrieval
///
/// Usage:
/// ```dart
/// class MyRemoteDataSourceImpl with AuthenticatedRemoteDataSourceMixin {
///   @override
///   FirebaseAuth get auth => _auth;
///   @override
///   ConnectivityService get connectivityService => _connectivityService;
/// }
/// ```
mixin AuthenticatedRemoteDataSourceMixin {
  /// Firebase Auth instance for authentication
  FirebaseAuth get auth;

  /// Connectivity service for checking network status
  ConnectivityService get connectivityService;

  /// Checks for connectivity and throws [NoInternetException] if offline.
  ///
  /// Call this before any network operation to ensure the device is online.
  Future<void> validateConnectivity() async {
    final isConnected = await connectivityService.checkConnection();
    if (!isConnected) {
      throw NoInternetException();
    }
  }

  /// Gets the Firebase Auth ID token for the current user.
  ///
  /// Throws an [Exception] if no user is currently authenticated.
  /// Returns the ID token string for use in authenticated API calls.
  Future<String> getAuthToken() async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken() ?? '';
  }

  /// Gets the current user's UID.
  ///
  /// Returns null if no user is authenticated.
  String? get currentUserId => auth.currentUser?.uid;

  /// Checks if a user is currently authenticated.
  bool get isAuthenticated => auth.currentUser != null;
}
