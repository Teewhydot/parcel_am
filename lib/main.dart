import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parcel_am/app/bloc_providers.dart';
import 'package:provider/provider.dart';
import 'package:parcel_am/app/init.dart';
import 'package:parcel_am/features/notifications/services/notification_service.dart';
import 'package:parcel_am/features/chat/services/presence_service.dart';
import 'package:parcel_am/core/utils/logger.dart';
import 'package:parcel_am/features/passkey/data/datasources/passkey_remote_data_source.dart';
import 'package:parcel_am/injection_container.dart' as di;

import 'core/routes/getx_route_module.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/parcel_am_core/data/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    // Initialize Firebase and dependency injection
    await AppConfig.init();

    // Register background message handler BEFORE any service initialization
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize NotificationService after Firebase and DI, before runApp
    final notificationService = di.sl<NotificationService>();
    await notificationService.initialize();

    // Initialize PresenceService to track user online/offline status app-wide
    // This uses WidgetsBindingObserver to detect app lifecycle changes
    final presenceService = di.sl<PresenceService>();
    presenceService.initialize();

    // Initialize Corbado Passkey SDK
    await _initializeCorbado();

    runApp(MultiBlocProvider(providers: blocs, child: const MyApp()));
  } catch (e) {
    // Handle Firebase initialization errors
    runApp(FirebaseErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: GetMaterialApp(
            title: 'ParcelAm',
            theme: AppTheme.lightTheme,
            initialRoute: Routes.initial,
            getPages: GetXRouteModule.routes,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

/// Initialize Corbado SDK for passkey authentication
Future<void> _initializeCorbado() async {
  try {
    final projectId = dotenv.env['CORBADO_PROJECT_ID'];
    if (projectId == null ||
        projectId.isEmpty ||
        projectId == 'your_corbado_project_id_here') {
      Logger.logWarning(
        'Corbado Project ID not configured. Passkey authentication will be disabled.',
      );
      return;
    }

    final passkeyDataSource = di.sl<PasskeyRemoteDataSource>();
    await passkeyDataSource.initialize(projectId);
    Logger.logSuccess('Corbado SDK initialized successfully');
  } catch (e) {
    Logger.logError('Failed to initialize Corbado SDK: $e');
    // Don't fail the app, just disable passkey functionality
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;

  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // Note: Cannot use AppSpacing/AppText here as ScreenUtil is not initialized
    return MaterialApp(
      title: 'Parcel AM - Firebase Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Please check your Firebase configuration:\n\n$error',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Cannot restart app programmatically - user must restart manually
                  },
                  child: const Text('Restart App Manually'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
