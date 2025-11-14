# Platform-Specific Code Best Practices

## Platform Detection
- Use Platform.isIOS, Platform.isAndroid for runtime platform checks
- Use defaultTargetPlatform from foundation.dart for platform-aware widgets
- Use Theme.of(context).platform when you need to follow Material platform conventions
- Avoid platform checks in business logic - keep them in UI layer only
- Use kIsWeb to detect web platform
- Check Platform before using platform-specific APIs to avoid runtime errors

## Platform Channels (Method Channels)
- Create separate platform channel implementations per platform (android/, ios/, windows/, etc.)
- Use MethodChannel for calling native platform methods from Dart
- Use EventChannel for streaming data from native to Dart
- Use BasicMessageChannel for custom message codecs
- Keep channel names unique and namespaced: 'com.yourapp.feature/method_name'
- Handle platform exceptions gracefully with try-catch
- Document expected method names and parameters clearly
- Return Future from platform channel calls - they're always async

## iOS-Specific Implementation
- Keep iOS code in ios/Runner directory
- Use Swift for new iOS code (avoid Objective-C unless necessary)
- Implement FlutterPlugin protocol in platform-specific classes
- Update Info.plist for required permissions (camera, location, etc.)
- Test on physical iOS devices - simulators don't support all features
- Handle iOS app lifecycle events (AppLifecycleState)
- Follow iOS Human Interface Guidelines for platform conventions
- Use CocoaPods for iOS dependency management

## Android-Specific Implementation
- Keep Android code in android/app/src/main directory
- Use Kotlin for new Android code (avoid Java unless necessary)
- Implement FlutterPlugin interface in platform-specific classes
- Update AndroidManifest.xml for permissions and app configuration
- Handle Android permissions with permission_handler package
- Test on various Android API levels (minimum API 21+)
- Follow Material Design guidelines for Android
- Use Gradle for Android dependency management
- Handle Android back button behavior appropriately

## Platform-Adaptive UI
- Use platform-specific widgets when appropriate (Material vs Cupertino)
- Create adaptive widgets that switch based on platform automatically
- Use showDialog vs showCupertinoDialog based on platform
- Use Switch.adaptive, Slider.adaptive for platform-appropriate controls
- Consider using flutter_platform_widgets package for consistent adaptive UI
- Follow platform conventions for navigation patterns (bottom nav vs tabs)
- Use platform-appropriate date/time pickers

## Permissions
- Always request permissions at runtime, not just in manifests
- Use permission_handler package for consistent cross-platform permission handling
- Request permissions with context - explain why you need them
- Handle permission denied gracefully - provide fallback or explanation
- Check permission status before attempting to use protected features
- Required Android permissions: add to AndroidManifest.xml
- Required iOS permissions: add usage descriptions to Info.plist

## Native Dependencies
- Use pubspec.yaml to declare Flutter plugin dependencies
- Use platform-specific dependency managers for native libs (CocoaPods, Gradle)
- Keep native dependencies minimal - prefer pure Dart packages when possible
- Document required native SDK versions and configuration
- Test after adding native dependencies on both platforms
- Handle native dependency conflicts carefully

## Platform-Specific Assets
- Organize platform-specific assets in android/app/src/main/res and ios/Runner/Assets.xcassets
- Use separate launch icons for each platform
- Configure splash screens per platform (use flutter_native_splash package)
- Follow platform icon size and format requirements
- Test app icons and launch screens on real devices

## File System & Storage
- Use path_provider for platform-appropriate directory paths
- Use getApplicationDocumentsDirectory() for user data storage
- Use getTemporaryDirectory() for cache/temp files
- Use getExternalStorageDirectory() (Android only) for user-accessible files
- Handle platform differences in file paths (/ vs \)
- Use shared_preferences for simple key-value storage across platforms

## App Lifecycle
- Listen to AppLifecycleState changes for proper resource management
- Handle paused, resumed, inactive, and detached states
- Clean up resources when app goes to background
- Refresh data when app returns to foreground if needed
- Handle deep links when app is launched from background
- Save user state before app is paused or terminated

## Web Considerations
- Use kIsWeb constant to detect web platform
- Handle web-specific behaviors (no file system access, different navigation)
- Use html package for web-specific APIs when needed
- Configure web-specific metadata in web/index.html
- Test on multiple browsers (Chrome, Safari, Firefox, Edge)
- Handle responsive design for desktop web viewports
- Implement PWA features if targeting web as primary platform

## Desktop Considerations (Windows, macOS, Linux)
- Test on target desktop platforms - don't assume cross-platform compatibility
- Handle larger screen sizes and mouse/keyboard input
- Implement proper window management and multi-window support
- Use platform-specific menu bars and system tray integration when needed
- Follow platform-specific HIG (Human Interface Guidelines)
- Package and distribute using platform-appropriate installers

## Testing Platform Code
- Write platform-specific tests in android/ and ios/ directories
- Use integration_test package for cross-platform integration tests
- Mock platform channels in widget tests using TestDefaultBinaryMessenger
- Test on real devices for both iOS and Android
- Use platform-specific CI/CD for automated testing on each platform