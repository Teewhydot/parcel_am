import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

import '../firebase_options.dart';
import '../injection_container.dart' as di;

class AppConfig {
  static Future<void> init() async {
    // Initialize app configurations here
    // For example, setting up environment variables, logging, etc.
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize dependency injection
    await di.init();

    // Initialize enhanced BLoC factories
    // await RecentKeywordsDatabaseService().database;
    // await AddressDatabaseService().database;
    // await UserProfileDatabaseService().database;
    // await dotenv.load(fileName: ".env");
  }
}
