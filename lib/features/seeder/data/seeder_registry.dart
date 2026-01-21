import '../domain/seeder.dart';
import 'seeders/bank_seeder.dart';

/// Registry of all available seeders in the application.
///
/// Add new seeders here to make them available in the seeding UI.
///
/// Example:
/// ```dart
/// class SeederRegistry {
///   static List<Seeder> get all => [
///     BankSeeder(),
///     CategorySeeder(),
///     ConfigSeeder(),
///   ];
/// }
/// ```
class SeederRegistry {
  /// All available seeders
  static List<Seeder> get all => [
    BankSeeder(),
  ];

  /// Get a seeder by name
  static Seeder? getByName(String name) {
    try {
      return all.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Get a seeder by collection name
  static Seeder? getByCollection(String collectionName) {
    try {
      return all.firstWhere((s) => s.collectionName == collectionName);
    } catch (_) {
      return null;
    }
  }
}
