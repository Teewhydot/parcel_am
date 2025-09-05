import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

import '../firebase_options.dart';

class AppConfig {
  static Future<void> init() async {
    // Initialize app configurations here
    // For example, setting up environment variables, logging, etc.
    WidgetsFlutterBinding.ensureInitialized();
    // setupDIService();
    await init();
    // Initialize enhanced BLoC factories

    // await RecentKeywordsDatabaseService().database;
    // await AddressDatabaseService().database;
    // await UserProfileDatabaseService().database;
    // await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
