import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:parcel_am/app/init.dart';
import 'package:parcel_am/core/services/notification_service.dart';
import 'package:parcel_am/injection_container.dart' as di;

import 'core/routes/getx_route_module.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'features/travellink/data/providers/theme_provider.dart';
import 'features/travellink/presentation/bloc/wallet/wallet_bloc.dart';
import 'features/travellink/presentation/bloc/wallet/wallet_event.dart';
import 'features/travellink/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/travellink/presentation/bloc/parcel/parcel_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase and dependency injection
    await AppConfig.init();

    // Register background message handler BEFORE any service initialization
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize NotificationService after Firebase and DI, before runApp
    final notificationService = di.sl<NotificationService>();
    await notificationService.initialize();

    runApp(const MyApp());
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
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                create: (_) => AuthBloc(),
              ),
              BlocProvider<DashboardBloc>(
                create: (context) => DashboardBloc(),
              ),
              BlocProvider(
                create: (_) => WalletBloc()..add(const WalletLoadRequested()),
              ),
              BlocProvider<NotificationBloc>(
                create: (_) => NotificationBloc(),
              ),
              BlocProvider<ParcelBloc>(
                create: (_) => ParcelBloc(),
              ),
            ],
            child: GetMaterialApp(
              title: 'ParcelAm',
              theme: AppTheme.lightTheme,
              initialRoute: Routes.initial,
              getPages: GetXRouteModule.routes,
              debugShowCheckedModeBanner: false,
            ),
          ),
        );
      },
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;

  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelLink - Firebase Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Please check your Firebase configuration:\n\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
