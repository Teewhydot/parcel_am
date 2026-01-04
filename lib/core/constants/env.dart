import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String? firebaseCloudFunctionsUrl = dotenv.env['FIREBASE_FUNCTIONS_URL'];
  static String? imageKitPrivateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'];
  static String? imageKitUrlEndpoint = dotenv.env['IMAGEKIT_URL_ENDPOINT'];
}
