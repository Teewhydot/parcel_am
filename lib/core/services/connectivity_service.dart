import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Service for monitoring internet connectivity status.
///
/// Provides:
/// - Real-time connectivity monitoring
/// - Connection status checks
/// - Stream of connectivity changes
class ConnectivityService {
  final InternetConnectionChecker _connectionChecker;
  StreamSubscription<InternetConnectionStatus>? _subscription;

  // Stream controller for broadcasting connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();

  // Cache the current connectivity status
  bool _isConnected = true;

  ConnectivityService({
    InternetConnectionChecker? connectionChecker,
  }) : _connectionChecker = connectionChecker ?? InternetConnectionChecker.instance;

  /// Returns a stream of connectivity status changes.
  /// Emits true when connected, false when disconnected.
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Returns the current connectivity status.
  bool get isConnected => _isConnected;

  /// Starts monitoring connectivity changes.
  void startMonitoring() {
    _subscription?.cancel();

    _subscription = _connectionChecker.onStatusChange.listen(
      (InternetConnectionStatus status) {
        final isConnected = status == InternetConnectionStatus.connected;
        if (_isConnected != isConnected) {
          _isConnected = isConnected;
          _connectivityController.add(isConnected);
        }
      },
    );

    // Check initial status
    _checkInitialStatus();
  }

  /// Checks the initial connectivity status.
  Future<void> _checkInitialStatus() async {
    try {
      final hasConnection = await _connectionChecker.hasConnection;
      _isConnected = hasConnection;
      _connectivityController.add(hasConnection);
    } catch (e) {
      // If check fails, assume connected
      _isConnected = true;
      _connectivityController.add(true);
    }
  }

  /// Manually checks if device has internet connection.
  /// Returns true if connected, false otherwise.
  Future<bool> checkConnection() async {
    try {
      final hasConnection = await _connectionChecker.hasConnection;
      _isConnected = hasConnection;
      return hasConnection;
    } catch (e) {
      // If check fails, assume connected to avoid blocking operations
      return true;
    }
  }

  /// Stops monitoring connectivity changes and cleans up resources.
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
