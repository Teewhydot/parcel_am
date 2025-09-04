import 'package:geolocator/geolocator.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/logger.dart';

/// A service to handle various app permissions in a centralized way
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request location permission using Geolocator
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Logger.logError('Location services are disabled');
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Logger.logError('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Logger.logError('Location permissions are permanently denied');
      return false;
    }

    // Save granted status to database
    Logger.logSuccess('Location permission granted');
    return true;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    Logger.logBasic('Requesting camera permission');

    final status = await Permission.camera.request();
    final isGranted = status.isGranted;

    // Save status to database

    if (isGranted) {
      Logger.logSuccess('Camera permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      Logger.logError('Camera permission permanently denied');
      return false;
    } else {
      Logger.logError('Camera permission denied: $status');
      return false;
    }
  }

  /// Request storage/photos permission
  Future<bool> requestStoragePermission() async {
    Logger.logBasic('Requesting storage permission');

    // Different permissions for different platforms
    Permission storagePermission;

    // Platform-specific permission handling
    if (GetPlatform.isIOS) {
      // iOS uses photos permission
      storagePermission = Permission.photos;
    } else {
      // Android and other platforms use storage permission
      storagePermission = Permission.storage;
    }

    final status = await storagePermission.request();
    final isGranted = status.isGranted;

    // Save status to database

    if (isGranted) {
      Logger.logSuccess('Storage permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      Logger.logError('Storage permission permanently denied');
      return false;
    } else {
      Logger.logError('Storage permission denied: $status');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    Logger.logBasic('Requesting notification permission');

    final status = await Permission.notification.request();
    final isGranted = status.isGranted;

    // Save status to database

    if (isGranted) {
      Logger.logSuccess('Notification permission granted');
      return true;
    } else {
      Logger.logError('Notification permission denied: $status');
      return false;
    }
  }

  /// Open app settings page
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
