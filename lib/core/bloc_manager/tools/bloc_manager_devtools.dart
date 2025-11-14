import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../communication/bloc_event_bus.dart';
import '../communication/cross_bloc_communication.dart';
import '../bloc_lifecycle_observer.dart';

/// Developer tools for BlocManager system debugging and monitoring
class BlocManagerDevTools {
  static BlocManagerDevTools? _instance;
  static BlocManagerDevTools get instance => _instance ??= BlocManagerDevTools._();

  BlocManagerDevTools._();

  final BlocEventBus _eventBus = BlocEventBus.instance;
  final CrossBlocCommunication _communication = CrossBlocCommunication.instance;
  final DefaultBlocLifecycleObserver _observer = DefaultBlocLifecycleObserver();
  
  final StreamController<DevToolsEvent> _eventController = StreamController.broadcast();
  final List<DevToolsEvent> _eventHistory = [];
  bool _isRecording = false;

  /// Stream of development tool events
  Stream<DevToolsEvent> get events => _eventController.stream;

  /// Get event history
  List<DevToolsEvent> get eventHistory => List.unmodifiable(_eventHistory);

  /// Whether recording is active
  bool get isRecording => _isRecording;

  /// Start recording events
  void startRecording() {
    _isRecording = true;
    _logEvent(DevToolsEvent(
      type: DevToolsEventType.system,
      message: 'Recording started',
      timestamp: DateTime.now(),
    ));
  }

  /// Stop recording events
  void stopRecording() {
    _isRecording = false;
    _logEvent(DevToolsEvent(
      type: DevToolsEventType.system,
      message: 'Recording stopped',
      timestamp: DateTime.now(),
    ));
  }

  /// Clear event history
  void clearHistory() {
    _eventHistory.clear();
    _logEvent(DevToolsEvent(
      type: DevToolsEventType.system,
      message: 'History cleared',
      timestamp: DateTime.now(),
    ));
  }

  /// Log a development event
  void _logEvent(DevToolsEvent event) {
    if (_isRecording) {
      _eventHistory.add(event);
      _eventController.add(event);
    }
    
    if (kDebugMode) {
      debugPrint('[BlocManagerDevTools] ${event.timestamp}: ${event.message}');
    }
  }

  /// Get comprehensive system statistics
  Map<String, dynamic> getSystemStats() {
    final eventBusStats = _eventBus.getStatistics();
    final communicationStats = _communication.getStatistics();
    final lifecycleStats = _observer.getStatistics();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'eventBus': eventBusStats,
      'crossBlocCommunication': communicationStats,
      'lifecycle': lifecycleStats,
      'devTools': {
        'recording': _isRecording,
        'eventHistoryCount': _eventHistory.length,
        'activeEventStreams': _eventController.hasListener ? 1 : 0,
      },
    };
  }

  /// Export system statistics to JSON
  String exportStats() {
    final stats = getSystemStats();
    return const JsonEncoder.withIndent('  ').convert(stats);
  }

  /// Monitor BLoC lifecycle events
  void monitorLifecycle() {
    // TODO: Implement proper lifecycle monitoring
    // The current implementation needs to be refactored to work with the observer pattern
  }

  /// Monitor event bus activity
  void monitorEventBus() {
    // Note: This would require modifications to BlocEventBus to expose monitoring hooks
    _logEvent(DevToolsEvent(
      type: DevToolsEventType.system,
      message: 'Event bus monitoring started',
      timestamp: DateTime.now(),
    ));
  }

  /// Monitor cross-BLoC communication
  void monitorCrossBlocCommunication() {
    // Note: This would require modifications to CrossBlocCommunication to expose monitoring hooks
    _logEvent(DevToolsEvent(
      type: DevToolsEventType.system,
      message: 'Cross-BLoC communication monitoring started',
      timestamp: DateTime.now(),
    ));
  }

  /// Check for memory leaks
  Future<List<String>> checkMemoryLeaks() async {
    final leaks = _observer.checkForLeaks();
    
    if (leaks.isNotEmpty) {
      _logEvent(DevToolsEvent(
        type: DevToolsEventType.warning,
        message: 'Memory leaks detected: ${leaks.join(', ')}',
        timestamp: DateTime.now(),
        data: {'leaks': leaks},
      ));
    } else {
      _logEvent(DevToolsEvent(
        type: DevToolsEventType.info,
        message: 'No memory leaks detected',
        timestamp: DateTime.now(),
      ));
    }
    
    return leaks;
  }

  /// Generate performance report
  Map<String, dynamic> generatePerformanceReport() {
    final stats = getSystemStats();
    final leaks = _observer.checkForLeaks();
    
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'performance': {
        'activeBlocsCount': stats['lifecycle']['activeBlocCount'] ?? 0,
        'totalCreatedCount': stats['lifecycle']['totalCreatedCount'] ?? 0,
        'activeEventControllers': stats['eventBus']['activeControllers'] ?? 0,
        'totalEventsEmitted': stats['eventBus']['totalEventsEmitted'] ?? 0,
        'registeredBlocsCount': stats['crossBlocCommunication']['registeredBlocs'] ?? 0,
      },
      'health': {
        'hasMemoryLeaks': leaks.isNotEmpty,
        'memoryLeaks': leaks,
        'eventHistorySize': _eventHistory.length,
      },
      'recommendations': _generateRecommendations(stats, leaks),
    };
    
    _logEvent(DevToolsEvent(
      type: DevToolsEventType.info,
      message: 'Performance report generated',
      timestamp: DateTime.now(),
      data: report,
    ));
    
    return report;
  }

  List<String> _generateRecommendations(Map<String, dynamic> stats, List<String> leaks) {
    final recommendations = <String>[];
    
    // Check for memory leaks
    if (leaks.isNotEmpty) {
      recommendations.add('Memory leaks detected. Consider reviewing BLoC disposal logic.');
    }
    
    // Check for excessive BLoCs
    final activeBlocsCount = stats['lifecycle']['activeBlocCount'] as int? ?? 0;
    if (activeBlocsCount > 20) {
      recommendations.add('High number of active BLoCs ($activeBlocsCount). Consider optimizing lifecycle management.');
    }
    
    // Check for excessive events
    final totalEvents = stats['eventBus']['totalEventsEmitted'] as int? ?? 0;
    if (totalEvents > 1000) {
      recommendations.add('High event volume ($totalEvents). Consider implementing event filtering or throttling.');
    }
    
    // Check event history size
    if (_eventHistory.length > 500) {
      recommendations.add('Large event history (${_eventHistory.length}). Consider clearing history periodically.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('System performance looks good!');
    }
    
    return recommendations;
  }

  /// Copy data to clipboard (for debugging)
  Future<void> copyToClipboard(String data) async {
    await Clipboard.setData(ClipboardData(text: data));
    _logEvent(DevToolsEvent(
      type: DevToolsEventType.info,
      message: 'Data copied to clipboard',
      timestamp: DateTime.now(),
    ));
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _instance = null;
  }
}

/// Types of development tool events
enum DevToolsEventType {
  system,
  lifecycle,
  communication,
  persistence,
  performance,
  error,
  warning,
  info,
}

/// Development tool event data structure
class DevToolsEvent {
  final DevToolsEventType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const DevToolsEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.data,
  });

  @override
  String toString() {
    return '${type.name.toUpperCase()}: $message';
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

/// Flutter widget for displaying BlocManager developer tools
class BlocManagerDevToolsWidget extends StatefulWidget {
  const BlocManagerDevToolsWidget({super.key});

  @override
  State<BlocManagerDevToolsWidget> createState() => _BlocManagerDevToolsWidgetState();
}

class _BlocManagerDevToolsWidgetState extends State<BlocManagerDevToolsWidget> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BlocManagerDevTools _devTools = BlocManagerDevTools.instance;
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _devTools.startRecording();
    _devTools.monitorLifecycle();
    
    // Update stats every 2 seconds
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statsTimer?.cancel();
    _devTools.stopRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlocManager DevTools'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Events'),
            Tab(text: 'Performance'),
            Tab(text: 'Actions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildEventsTab(),
          _buildPerformanceTab(),
          _buildActionsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _devTools.getSystemStats();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Overview', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _buildStatRow('Recording', _devTools.isRecording ? 'Active' : 'Inactive'),
                  _buildStatRow('Event History', '${_devTools.eventHistory.length} events'),
                  _buildStatRow('Active BLoCs', '${stats['lifecycle']['activeBlocCount'] ?? 0}'),
                  _buildStatRow('Total Events', '${stats['eventBus']['totalEventsEmitted'] ?? 0}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final leaks = await _devTools.checkMemoryLeaks();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Found ${leaks.length} memory leaks')),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Check Leaks'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final report = _devTools.generatePerformanceReport();
                          _devTools.copyToClipboard(const JsonEncoder.withIndent('  ').convert(report));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Performance report copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.assessment),
                        label: const Text('Performance Report'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<DevToolsEvent>(
      stream: _devTools.events,
      builder: (context, snapshot) {
        final events = _devTools.eventHistory.reversed.toList();
        
        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              leading: _getEventIcon(event.type),
              title: Text(event.message),
              subtitle: Text(event.timestamp.toString()),
              dense: true,
            );
          },
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    final report = _devTools.generatePerformanceReport();
    final performance = report['performance'] as Map<String, dynamic>;
    final health = report['health'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Performance Metrics', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  ...performance.entries.map((e) => _buildStatRow(
                    e.key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}'),
                    '${e.value}',
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Check', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _buildHealthIndicator(
                    'Memory Leaks',
                    health['hasMemoryLeaks'] as bool,
                  ),
                  if (health['memoryLeaks'] != null && (health['memoryLeaks'] as List).isNotEmpty)
                    ...( health['memoryLeaks'] as List).map((leak) => 
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text('• $leak', style: const TextStyle(color: Colors.red)),
                      )
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recording Controls', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _devTools.isRecording ? _devTools.stopRecording : _devTools.startRecording,
                        icon: Icon(_devTools.isRecording ? Icons.stop : Icons.play_arrow),
                        label: Text(_devTools.isRecording ? 'Stop Recording' : 'Start Recording'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _devTools.clearHistory,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear History'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export & Import', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final stats = _devTools.exportStats();
                          _devTools.copyToClipboard(stats);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Statistics exported to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Export Stats'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final events = _devTools.eventHistory.map((e) => e.toJson()).toList();
                          final json = const JsonEncoder.withIndent('  ').convert(events);
                          _devTools.copyToClipboard(json);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event history exported to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Export Events'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String label, bool hasIssue) {
    return Row(
      children: [
        Icon(
          hasIssue ? Icons.warning : Icons.check_circle,
          color: hasIssue ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          hasIssue ? 'Issues Found' : 'OK',
          style: TextStyle(
            color: hasIssue ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Icon _getEventIcon(DevToolsEventType type) {
    switch (type) {
      case DevToolsEventType.system:
        return const Icon(Icons.settings, color: Colors.blue);
      case DevToolsEventType.lifecycle:
        return const Icon(Icons.refresh, color: Colors.green);
      case DevToolsEventType.communication:
        return const Icon(Icons.message, color: Colors.purple);
      case DevToolsEventType.persistence:
        return const Icon(Icons.save, color: Colors.orange);
      case DevToolsEventType.performance:
        return const Icon(Icons.speed, color: Colors.indigo);
      case DevToolsEventType.error:
        return const Icon(Icons.error, color: Colors.red);
      case DevToolsEventType.warning:
        return const Icon(Icons.warning, color: Colors.amber);
      case DevToolsEventType.info:
        return const Icon(Icons.info, color: Colors.cyan);
    }
  }
}