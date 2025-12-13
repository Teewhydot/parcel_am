import 'package:flutter/material.dart';
import '../../data/seeder_registry.dart';
import '../../domain/seeder.dart';
import '../../domain/seeder_service.dart';

/// Screen for seeding database collections.
///
/// Displays all available seeders and allows running them individually
/// or all at once. Shows progress and results for each seeder.
class DatabaseSeederScreen extends StatefulWidget {
  const DatabaseSeederScreen({super.key});

  @override
  State<DatabaseSeederScreen> createState() => _DatabaseSeederScreenState();
}

class _DatabaseSeederScreenState extends State<DatabaseSeederScreen> {
  final SeederService _seederService = SeederService();
  final Map<String, _SeederStatus> _seederStatuses = {};
  bool _isRunningAll = false;

  @override
  void initState() {
    super.initState();
    _initializeStatuses();
    _checkAllCollections();
  }

  void _initializeStatuses() {
    for (final seeder in SeederRegistry.all) {
      _seederStatuses[seeder.name] = _SeederStatus();
    }
  }

  Future<void> _checkAllCollections() async {
    for (final seeder in SeederRegistry.all) {
      await _checkCollection(seeder);
    }
  }

  Future<void> _checkCollection(Seeder seeder) async {
    setState(() {
      _seederStatuses[seeder.name]?.isChecking = true;
    });

    try {
      final count = await _seederService.getCollectionCount(seeder.collectionName);
      setState(() {
        _seederStatuses[seeder.name]?.existingCount = count;
        _seederStatuses[seeder.name]?.isChecking = false;
      });
    } catch (e) {
      setState(() {
        _seederStatuses[seeder.name]?.error = e.toString();
        _seederStatuses[seeder.name]?.isChecking = false;
      });
    }
  }

  Future<void> _runSeeder(Seeder seeder, {bool forceReseed = false}) async {
    final status = _seederStatuses[seeder.name];
    if (status == null || status.isRunning) return;

    setState(() {
      status.isRunning = true;
      status.progress = 0;
      status.currentItem = '';
      status.result = null;
      status.error = null;
    });

    final result = await _seederService.runSeeder(
      seeder,
      forceReseed: forceReseed,
      onProgress: (current, total, item) {
        setState(() {
          status.progress = (current / total * 100).round();
          status.currentItem = item;
        });
      },
    );

    setState(() {
      status.isRunning = false;
      status.result = result;
      if (result.success) {
        status.existingCount = (status.existingCount ?? 0) + result.itemsSeeded;
      }
    });
  }

  Future<void> _runAllSeeders() async {
    setState(() {
      _isRunningAll = true;
    });

    for (final seeder in SeederRegistry.all) {
      await _runSeeder(seeder);
    }

    setState(() {
      _isRunningAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seeders = SeederRegistry.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Seeder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunningAll ? null : _checkAllCollections,
            tooltip: 'Refresh counts',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Database Seeders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${seeders.length} seeders available',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // Seeder List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: seeders.length,
              itemBuilder: (context, index) {
                final seeder = seeders[index];
                final status = _seederStatuses[seeder.name] ?? _SeederStatus();
                return _SeederCard(
                  seeder: seeder,
                  status: status,
                  onRun: () => _runSeeder(seeder),
                  onForceReseed: () => _runSeeder(seeder, forceReseed: true),
                  onCheck: () => _checkCollection(seeder),
                  isDisabled: _isRunningAll,
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRunningAll ? null : _runAllSeeders,
                  icon: _isRunningAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunningAll ? 'Running...' : 'Run All Seeders'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeederStatus {
  bool isChecking = false;
  bool isRunning = false;
  int? existingCount;
  int progress = 0;
  String currentItem = '';
  SeederResult? result;
  String? error;
}

class _SeederCard extends StatelessWidget {
  final Seeder seeder;
  final _SeederStatus status;
  final VoidCallback onRun;
  final VoidCallback onForceReseed;
  final VoidCallback onCheck;
  final bool isDisabled;

  const _SeederCard({
    required this.seeder,
    required this.status,
    required this.onRun,
    required this.onForceReseed,
    required this.onCheck,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = (status.existingCount ?? 0) > 0;
    final isSuccessResult = status.result?.success == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(seeder.icon, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seeder.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        seeder.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(hasData),
              ],
            ),

            const SizedBox(height: 12),

            // Info Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildInfoChip(
                    Icons.folder,
                    seeder.collectionName,
                    'Collection',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoChip(
                    Icons.data_array,
                    '${seeder.itemCount}',
                    'Items to seed',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoChip(
                    Icons.check_circle,
                    status.isChecking ? '...' : '${status.existingCount ?? 0}',
                    'Existing',
                  ),
                ],
              ),
            ),

            // Progress (if running)
            if (status.isRunning) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: status.progress / 100),
              const SizedBox(height: 4),
              Text(
                '${status.progress}% - ${status.currentItem}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],

            // Result
            if (status.result != null && !status.isRunning) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSuccessResult ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSuccessResult ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuccessResult ? Icons.check_circle : Icons.error,
                      color: isSuccessResult ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.result!.message,
                        style: TextStyle(
                          color: isSuccessResult ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDisabled || status.isRunning ? null : onRun,
                    icon: status.isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow, size: 18),
                    label: Text(hasData ? 'Already Seeded' : 'Seed'),
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: isDisabled || status.isRunning ? null : onForceReseed,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reseed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool hasData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasData ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hasData ? 'Seeded' : 'Empty',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: hasData ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
