import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/core/routes/routes.dart';

void main() {
  group('Chat Routes Integration Tests', () {
    test('chatsList route should be defined', () {
      expect(Routes.chatsList, equals('/chatsList'));
    });

    test('chat route should be defined', () {
      expect(Routes.chat, equals('/chat'));
    });
  });
}
