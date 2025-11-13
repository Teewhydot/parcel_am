# Chat BLoCs - Real-time Stream Management

## Structure

```
lib/features/travellink/
├── domain/
│   ├── entities/chat/
│   │   ├── chat_entity.dart       # Chat model with participant & message info
│   │   ├── message_entity.dart    # Message model with content & metadata
│   │   └── presence_entity.dart   # Online status & typing indicator model
│   ├── repositories/chat/
│   │   └── chat_repository.dart   # Repository interface
│   └── usecases/chat/
│       ├── chat_usecase.dart      # Chat operations
│       ├── message_usecase.dart   # Message operations
│       └── presence_usecase.dart  # Presence operations
├── data/
│   ├── datasources/chat/
│   │   └── chat_remote_data_source.dart  # Firestore implementation
│   └── repositories/chat/
│       └── chat_repository_impl.dart     # Repository implementation
└── presentation/bloc/chat/
    ├── chat_bloc.dart             # Chat list management
    ├── chat_event.dart
    ├── chat_data.dart
    ├── message_bloc.dart          # Multi-chat message management
    ├── message_event.dart
    ├── message_data.dart
    ├── presence_bloc.dart         # Presence & typing management
    ├── presence_event.dart
    ├── presence_data.dart
    ├── chat_exports.dart          # Convenience exports
    └── USAGE.md                   # Detailed usage guide
```

## Key Features

### 1. ChatBloc
- Single stream subscription for user's chat list
- Auto-updates on Firestore changes
- Events: `ChatLoadRequested`, `ChatCreateRequested`, `ChatMarkAsRead`
- Proper cleanup on disposal

### 2. MessageBloc
- Multiple concurrent stream subscriptions (one per chat)
- Map-based subscription management: `Map<String, StreamSubscription>`
- Per-chat message history
- Events: `MessageLoadRequested`, `MessageSendRequested`, `MessageDeleteRequested`, `MessageUnsubscribeRequested`
- Individual chat cleanup or full disposal

### 3. PresenceBloc
- Dual subscription maps for presence and typing
- Real-time online status tracking
- Typing indicators per chat
- Events: `PresenceLoadRequested`, `PresenceUpdateRequested`, `TypingStarted`, `TypingEnded`
- Comprehensive cleanup on disposal

## Stream Management Pattern

All blocs follow this pattern:

```dart
// 1. Store subscriptions
StreamSubscription? _subscription;
Map<String, StreamSubscription> _subscriptions = {};

// 2. Cancel before creating new
await _subscription?.cancel();

// 3. Listen and add internal events
_subscription = useCase.watchData().listen(
  (either) {
    either.fold(
      (failure) => add(ErrorEvent(failure.failureMessage)),
      (data) => add(UpdatedEvent(data)),
    );
  },
  onError: (error) => add(ErrorEvent(error.toString())),
);

// 4. Cleanup on disposal
@override
Future<void> close() {
  _subscription?.cancel();
  _subscriptions.forEach((_, sub) => sub.cancel());
  return super.close();
}
```

## Firestore Structure

```
chats/
  {chatId}/
    participantIds: [userId1, userId2]
    lastMessage: "string"
    lastMessageTime: timestamp
    lastMessageSenderId: "userId"
    unreadCounts: {userId1: 0, userId2: 5}
    createdAt: timestamp
    updatedAt: timestamp
    
    messages/
      {messageId}/
        senderId: "userId"
        content: "message text"
        type: "text|image|file|system"
        timestamp: timestamp
        isRead: false
        readBy: [userId1]
        replyToId: "messageId" (optional)
        metadata: {}
    
    typing/
      {userId}/
        isTyping: true
        timestamp: timestamp

presence/
  {userId}/
    status: "online|offline|away"
    lastSeen: timestamp
    currentChatId: "chatId" (optional)
    isTyping: false
```

## Testing

Unit tests included for all three blocs:
- `test/features/travellink/presentation/bloc/chat/chat_bloc_test.dart`
- `test/features/travellink/presentation/bloc/chat/message_bloc_test.dart`
- `test/features/travellink/presentation/bloc/chat/presence_bloc_test.dart`

Run tests:
```bash
flutter test test/features/travellink/presentation/bloc/chat/
```

Generate mocks:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Dependencies

Already in pubspec.yaml:
- `flutter_bloc: ^8.1.6`
- `bloc: ^8.1.4`
- `equatable: ^2.0.5`
- `dartz: ^0.10.1`
- `cloud_firestore: ^6.1.0`
- `get_it: ^9.0.5`

## Next Steps

1. **Register in Dependency Injection** (`injection_container.dart`):
```dart
// Repositories
sl.registerLazySingleton<ChatRepository>(
  () => ChatRepositoryImpl(),
);

// Use Cases
sl.registerLazySingleton(() => ChatUseCase());
sl.registerLazySingleton(() => MessageUseCase());
sl.registerLazySingleton(() => PresenceUseCase());

// BLoCs
sl.registerFactory(() => ChatBloc());
sl.registerFactory(() => MessageBloc());
sl.registerFactory(() => PresenceBloc());
```

2. **Create UI Screens**:
- Chat list screen using ChatBloc
- Chat detail screen using MessageBloc & PresenceBloc
- User presence widgets

3. **Add Firebase Security Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
      }
      
      match /typing/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    match /presence/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

4. **Implement Push Notifications** for new messages (see `lib/core/services/push_notification_service.dart`)

See `USAGE.md` for detailed implementation examples.
