import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String? firebaseCloudFunctionsUrl = dotenv.env['FIREBASE_FUNCTIONS_URL'];

}
