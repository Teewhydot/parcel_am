import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_spacing.dart';
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
        title: AppText.titleLarge('Database Seeder'),
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
            color: AppColors.infoLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleLarge(
                  'Database Seeders',
                  fontWeight: FontWeight.bold,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText.bodyMedium(
                  '${seeders.length} seeders available',
                  color: AppColors.onSurfaceVariant,
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
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: AppButton.primary(
                onPressed: _isRunningAll ? null : _runAllSeeders,
                loading: _isRunningAll,
                fullWidth: true,
                child: AppText.bodyMedium(_isRunningAll ? 'Running...' : 'Run All Seeders'),
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

    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.infoLight,
                  child: Icon(seeder.icon, color: AppColors.infoDark),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyLarge(
                        seeder.name,
                        fontWeight: FontWeight.bold,
                      ),
                      AppText(
                        seeder.description,
                        variant: TextVariant.bodySmall,
                        fontSize: AppFontSize.md,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(hasData),
              ],
            ),

            AppSpacing.verticalSpacing(SpacingSize.md),

            // Info Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildInfoChip(
                    Icons.folder,
                    seeder.collectionName,
                    'Collection',
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.lg),
                  _buildInfoChip(
                    Icons.data_array,
                    '${seeder.itemCount}',
                    'Items to seed',
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.lg),
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
              AppSpacing.verticalSpacing(SpacingSize.md),
              LinearProgressIndicator(value: status.progress / 100),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText.bodySmall(
                '${status.progress}% - ${status.currentItem}',
                color: AppColors.onSurfaceVariant,
              ),
            ],

            // Result
            if (status.result != null && !status.isRunning) ...[
              AppSpacing.verticalSpacing(SpacingSize.md),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSuccessResult ? AppColors.successLight : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSuccessResult ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuccessResult ? Icons.check_circle : Icons.error,
                      color: isSuccessResult ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    Expanded(
                      child: AppText.bodyMedium(
                        status.result!.message,
                        color: isSuccessResult ? AppColors.successDark : AppColors.errorDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            AppSpacing.verticalSpacing(SpacingSize.md),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    onPressed: isDisabled || status.isRunning ? null : onRun,
                    loading: status.isRunning,
                    child: AppText.bodyMedium(hasData ? 'Already Seeded' : 'Seed'),
                  ),
                ),
                if (hasData) ...[
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  AppButton.outline(
                    onPressed: isDisabled || status.isRunning ? null : onForceReseed,
                    child: AppText.bodyMedium('Reseed'),
                  ),
                ],
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildStatusBadge(bool hasData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasData ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText.bodySmall(
        hasData ? 'Seeded' : 'Empty',
        fontWeight: FontWeight.w600,
        color: hasData ? AppColors.successDark : AppColors.warningDark,
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
              Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
              AppSpacing.horizontalSpacing(SpacingSize.xs),
              AppText.bodyMedium(
                value,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          AppText(
            label,
            variant: TextVariant.bodySmall,
            fontSize: AppFontSize.sm,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
