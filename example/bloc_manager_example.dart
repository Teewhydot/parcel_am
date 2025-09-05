import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:parcel_am/core/bloc_manager/bloc_manager.dart';
import 'package:parcel_am/core/bloc_manager/bloc_manager_config.dart';
import 'package:parcel_am/core/bloc_manager/communication/cross_bloc_communication.dart';
import 'package:parcel_am/core/bloc_manager/tools/bloc_manager_devtools.dart';

/// Comprehensive example demonstrating BlocManager features
void main() {
  // Setup dependency injection
  GetIt.instance.registerSingleton<ExampleService>(ExampleService());
  
  runApp(const BlocManagerExampleApp());
}

/// Example service for dependency injection
class ExampleService {
  Future<String> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return 'Hello from service!';
  }
}

/// Example app demonstrating BlocManager usage
class BlocManagerExampleApp extends StatelessWidget {
  const BlocManagerExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlocManager Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExampleHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Home screen with multiple BlocManager examples
class ExampleHomeScreen extends StatelessWidget {
  const ExampleHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlocManager Examples'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BlocManagerDevToolsWidget(),
                ),
              );
            },
            icon: const Icon(Icons.developer_mode),
            tooltip: 'Developer Tools',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildExampleCard(
            context,
            'Basic Counter Example',
            'Simple counter with state persistence',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CounterExampleScreen()),
            ),
          ),
          _buildExampleCard(
            context,
            'Cross-BLoC Communication',
            'Demonstrates inter-BLoC messaging',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrossBlocExampleScreen()),
            ),
          ),
          _buildExampleCard(
            context,
            'State Persistence',
            'State restoration and recovery',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersistenceExampleScreen()),
            ),
          ),
          _buildExampleCard(
            context,
            'Performance Monitoring',
            'Performance tracking and analytics',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerformanceExampleScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}

// ===============================================
// Counter Example - Basic BlocManager Usage
// ===============================================

abstract class CounterEvent {}
class CounterIncremented extends CounterEvent {}
class CounterDecremented extends CounterEvent {}
class CounterReset extends CounterEvent {}
class CounterLoadRequested extends CounterEvent {}

class CounterState {
  final int count;
  final bool isLoading;
  final String? error;

  const CounterState({
    this.count = 0,
    this.isLoading = false,
    this.error,
  });

  CounterState copyWith({
    int? count,
    bool? isLoading,
    String? error,
  }) {
    return CounterState(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'isLoading': isLoading,
    'error': error,
  };

  factory CounterState.fromJson(Map<String, dynamic> json) => CounterState(
    count: json['count'] ?? 0,
    isLoading: json['isLoading'] ?? false,
    error: json['error'],
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is CounterState &&
    runtimeType == other.runtimeType &&
    count == other.count &&
    isLoading == other.isLoading &&
    error == other.error;

  @override
  int get hashCode => count.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

class CounterBloc extends Bloc<CounterEvent, CounterState> 
    with CrossBlocCommunicationMixin<CounterEvent, CounterState> {
  
  CounterBloc() : super(const CounterState()) {
    on<CounterIncremented>(_onIncremented);
    on<CounterDecremented>(_onDecremented);
    on<CounterReset>(_onReset);
    on<CounterLoadRequested>(_onLoadRequested);
    
    // Register for cross-BLoC communication
    registerForCommunication('counter');
    
    // Listen to cross-BLoC events
    subscribeToCrossBlocEvents<String>(
      (message) => add(CounterReset()),
      eventKey: 'global_reset',
    );
  }

  void _onIncremented(CounterIncremented event, Emitter<CounterState> emit) {
    final newState = state.copyWith(count: state.count + 1);
    emit(newState);
    
    // Emit cross-BLoC event when count reaches milestone
    if (newState.count % 10 == 0) {
      emitCrossBlocEvent('counter_milestone', {
        'count': newState.count,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _onDecremented(CounterDecremented event, Emitter<CounterState> emit) {
    emit(state.copyWith(count: state.count - 1));
  }

  void _onReset(CounterReset event, Emitter<CounterState> emit) {
    emit(const CounterState());
    emitCrossBlocEvent('counter_reset', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onLoadRequested(CounterLoadRequested event, Emitter<CounterState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      // Simulate async operation
      await Future.delayed(const Duration(seconds: 1));
      final service = GetIt.instance<ExampleService>();
      await service.fetchData();
      
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    unregisterFromCommunication('counter');
    return super.close();
  }
}

class CounterExampleScreen extends StatelessWidget {
  const CounterExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Example')),
      body: BlocManager<CounterBloc, CounterState>(
        config: BlocManagerConfig.development(
          getIt: GetIt.instance,
        ),
        create: (_) => CounterBloc(),
        child: const CounterView(),
      ),
    );
  }
}

class CounterView extends StatelessWidget {
  const CounterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isLoading) const CircularProgressIndicator(),
              if (state.error != null)
                Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              Text(
                'Count: ${state.count}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: () => context.read<CounterBloc>().add(CounterDecremented()),
                    child: const Icon(Icons.remove),
                  ),
                  FloatingActionButton(
                    onPressed: () => context.read<CounterBloc>().add(CounterIncremented()),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.read<CounterBloc>().add(CounterReset()),
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () => context.read<CounterBloc>().add(CounterLoadRequested()),
                child: const Text('Async Load'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===============================================
// Cross-BLoC Communication Example
// ===============================================

abstract class MessageEvent {}
class MessageSent extends MessageEvent {
  final String message;
  MessageSent(this.message);
}
class GlobalResetRequested extends MessageEvent {}

class MessageState {
  final List<String> messages;
  final int messageCount;

  const MessageState({
    this.messages = const [],
    this.messageCount = 0,
  });

  MessageState copyWith({
    List<String>? messages,
    int? messageCount,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is MessageState &&
    runtimeType == other.runtimeType &&
    messages.toString() == other.messages.toString() &&
    messageCount == other.messageCount;

  @override
  int get hashCode => messages.hashCode ^ messageCount.hashCode;
}

class MessageBloc extends Bloc<MessageEvent, MessageState> 
    with CrossBlocCommunicationMixin<MessageEvent, MessageState> {
  
  MessageBloc() : super(const MessageState()) {
    on<MessageSent>(_onMessageSent);
    on<GlobalResetRequested>(_onGlobalResetRequested);
    
    registerForCommunication('message');
    
    // Listen to counter events
    subscribeToCrossBlocEvents<Map<String, dynamic>>(
      (data) {
        final count = data['count'] as int;
        add(MessageSent('Counter reached milestone: $count'));
      },
      eventKey: 'counter_milestone',
    );
    
    subscribeToCrossBlocEvents<Map<String, dynamic>>(
      (data) {
        add(MessageSent('Counter was reset'));
      },
      eventKey: 'counter_reset',
    );
  }

  void _onMessageSent(MessageSent event, Emitter<MessageState> emit) {
    final newMessages = [...state.messages, event.message];
    emit(state.copyWith(
      messages: newMessages,
      messageCount: state.messageCount + 1,
    ));
  }

  void _onGlobalResetRequested(GlobalResetRequested event, Emitter<MessageState> emit) {
    // Broadcast global reset to all BLoCs
    emitCrossBlocEvent('global_reset', 'Reset requested by user');
    emit(const MessageState());
  }

  @override
  Future<void> close() {
    unregisterFromCommunication('message');
    return super.close();
  }
}

class CrossBlocExampleScreen extends StatelessWidget {
  const CrossBlocExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cross-BLoC Communication')),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => CounterBloc(),
          ),
          BlocProvider(
            create: (_) => MessageBloc(),
          ),
        ],
        child: const CrossBlocView(),
      ),
    );
  }
}

class CrossBlocView extends StatelessWidget {
  const CrossBlocView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Counter section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Counter BLoC', style: TextStyle(fontWeight: FontWeight.bold)),
                  BlocBuilder<CounterBloc, CounterState>(
                    builder: (context, state) {
                      return Text('Count: ${state.count}', style: Theme.of(context).textTheme.headlineSmall);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.read<CounterBloc>().add(CounterDecremented()),
                        child: const Text('-'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.read<CounterBloc>().add(CounterIncremented()),
                        child: const Text('+'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Message section
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
                        ElevatedButton(
                          onPressed: () => context.read<MessageBloc>().add(GlobalResetRequested()),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Global Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: BlocBuilder<MessageBloc, MessageState>(
                        builder: (context, state) {
                          if (state.messages.isEmpty) {
                            return const Center(child: Text('No messages yet. Try incrementing the counter!'));
                          }
                          return ListView.builder(
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.message),
                                title: Text(state.messages[index]),
                                subtitle: Text('Message ${index + 1}'),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================
// Additional Example Screens (Placeholder)
// ===============================================

class PersistenceExampleScreen extends StatelessWidget {
  const PersistenceExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('State Persistence')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('State Persistence Example'),
            SizedBox(height: 8),
            Text('This demonstrates automatic state saving and restoration.'),
          ],
        ),
      ),
    );
  }
}

class PerformanceExampleScreen extends StatelessWidget {
  const PerformanceExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Monitoring')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Performance Monitoring Example'),
            SizedBox(height: 8),
            Text('This demonstrates performance tracking and analytics.'),
          ],
        ),
      ),
    );
  }
}