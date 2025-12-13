import 'package:flutter/material.dart';

/// Base class for all database seeders.
///
/// Implement this class to create seeders for different collections.
/// Each seeder should be self-contained and idempotent.
///
/// Example:
/// ```dart
/// class BankSeeder extends Seeder {
///   @override
///   String get name => 'Banks';
///
///   @override
///   String get description => 'Nigerian banks for withdrawals';
///
///   @override
///   String get collectionName => 'banks';
///
///   @override
///   List<Map<String, dynamic>> get seedData => [...];
/// }
/// ```
abstract class Seeder {
  /// Display name for the seeder
  String get name;

  /// Description of what this seeder does
  String get description;

  /// Firestore collection name to seed
  String get collectionName;

  /// The data to seed
  List<Map<String, dynamic>> get seedData;

  /// Optional: Document ID field. If null, uses auto-generated IDs.
  /// If specified, the value of this field in each seed item will be used as the document ID.
  String? get documentIdField => null;

  /// Optional: Icon for UI display
  IconData get icon => Icons.data_object;

  /// Number of items to seed
  int get itemCount => seedData.length;
}

/// Result of a seeding operation
class SeederResult {
  final bool success;
  final String message;
  final int itemsSeeded;
  final Duration duration;
  final String? error;

  const SeederResult({
    required this.success,
    required this.message,
    this.itemsSeeded = 0,
    this.duration = Duration.zero,
    this.error,
  });

  factory SeederResult.success({
    required int itemsSeeded,
    required Duration duration,
  }) {
    return SeederResult(
      success: true,
      message: 'Successfully seeded $itemsSeeded items',
      itemsSeeded: itemsSeeded,
      duration: duration,
    );
  }

  factory SeederResult.alreadySeeded(int existingCount) {
    return SeederResult(
      success: true,
      message: 'Collection already has $existingCount items',
      itemsSeeded: 0,
    );
  }

  factory SeederResult.error(String error) {
    return SeederResult(
      success: false,
      message: 'Seeding failed',
      error: error,
    );
  }
}

/// Callback for seeding progress updates
typedef SeederProgressCallback = void Function(int current, int total, String item);
