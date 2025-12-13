import 'package:cloud_firestore/cloud_firestore.dart';
import 'seeder.dart';

/// Service for running database seeders.
///
/// Handles the actual Firestore operations for seeding data.
class SeederService {
  final FirebaseFirestore _firestore;

  SeederService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check how many documents exist in a collection
  Future<int> getCollectionCount(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).count().get();
    return snapshot.count ?? 0;
  }

  /// Check if a collection has any documents
  Future<bool> isCollectionEmpty(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).limit(1).get();
    return snapshot.docs.isEmpty;
  }

  /// Run a seeder and return the result
  ///
  /// [seeder] - The seeder to run
  /// [forceReseed] - If true, will seed even if collection has data
  /// [onProgress] - Optional callback for progress updates
  Future<SeederResult> runSeeder(
    Seeder seeder, {
    bool forceReseed = false,
    SeederProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Check if collection already has data
      if (!forceReseed) {
        final existingCount = await getCollectionCount(seeder.collectionName);
        if (existingCount > 0) {
          stopwatch.stop();
          return SeederResult.alreadySeeded(existingCount);
        }
      }

      final collection = _firestore.collection(seeder.collectionName);
      final seedData = seeder.seedData;
      final total = seedData.length;

      // Use batched writes for efficiency (Firestore limit: 500 per batch)
      const batchSize = 500;
      int seededCount = 0;

      for (int i = 0; i < seedData.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < seedData.length) ? i + batchSize : seedData.length;

        for (int j = i; j < end; j++) {
          final item = seedData[j];

          // Determine document ID
          DocumentReference docRef;
          if (seeder.documentIdField != null && item.containsKey(seeder.documentIdField)) {
            docRef = collection.doc(item[seeder.documentIdField].toString());
          } else {
            docRef = collection.doc();
          }

          // Add timestamps
          final dataWithTimestamps = {
            ...item,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          batch.set(docRef, dataWithTimestamps);
          seededCount++;

          // Report progress
          onProgress?.call(seededCount, total, item['name']?.toString() ?? 'Item $seededCount');
        }

        await batch.commit();
      }

      stopwatch.stop();
      return SeederResult.success(
        itemsSeeded: seededCount,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return SeederResult.error(e.toString());
    }
  }

  /// Run multiple seeders sequentially
  Future<Map<String, SeederResult>> runSeeders(
    List<Seeder> seeders, {
    bool forceReseed = false,
    void Function(Seeder seeder, SeederResult result)? onSeederComplete,
  }) async {
    final results = <String, SeederResult>{};

    for (final seeder in seeders) {
      final result = await runSeeder(seeder, forceReseed: forceReseed);
      results[seeder.name] = result;
      onSeederComplete?.call(seeder, result);
    }

    return results;
  }

  /// Clear a collection (use with caution!)
  Future<void> clearCollection(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
