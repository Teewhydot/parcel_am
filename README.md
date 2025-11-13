# parcel_am

A new Flutter project.

## Chat Feature - Real-time Stream Management

### Overview
The chat feature implements real-time communication with Firebase Firestore streams, featuring:
- ChatBloc: User chat list management with auto-updates
- MessageBloc: Per-chat message streams with automatic cleanup
- PresenceBloc: Online status and typing indicators

### Architecture

#### ChatBloc
- **Purpose**: Manages user's chat list with real-time updates
- **Stream**: Single subscription to `watchUserChats(userId)` that auto-emits on Firestore changes
- **Lifecycle**: Stream established on `ChatLoadRequested`, canceled on bloc disposal
- **Events**:
  - `ChatLoadRequested(userId)`: Start watching user's chats
  - `ChatCreateRequested(participantIds)`: Create new chat
  - `ChatMarkAsRead(chatId, userId)`: Mark chat as read
  - `ChatUpdated(chats)`: Internal event from stream
  - `ChatStreamError(error)`: Internal error handling

#### MessageBloc
- **Purpose**: Manages messages for multiple chats simultaneously
- **Streams**: Multiple per-chat subscriptions stored in `Map<String, StreamSubscription>`
- **Lifecycle**: Each chat gets its own stream on `MessageLoadRequested`, canceled individually or on bloc disposal
- **Events**:
  - `MessageLoadRequested(chatId)`: Start watching chat messages
  - `MessageSendRequested(...)`: Send new message
  - `MessageDeleteRequested(messageId)`: Delete message
  - `MessageUnsubscribeRequested(chatId)`: Stop watching specific chat
  - `MessagesUpdated(chatId, messages)`: Internal event from stream
  - `MessageStreamError(chatId, error)`: Internal error handling

#### PresenceBloc
- **Purpose**: Tracks online status and typing indicators
- **Streams**: 
  - User presence subscriptions: `Map<String, StreamSubscription>`
  - Typing status subscriptions: `Map<String, StreamSubscription>`
- **Lifecycle**: Subscriptions managed per user/chat, cleaned up on disposal
- **Events**:
  - `PresenceLoadRequested(userId)`: Watch user presence
  - `PresenceUpdateRequested(...)`: Update own status
  - `TypingStarted(userId, chatId)`: User starts typing
  - `TypingEnded(userId, chatId)`: User stops typing
  - `PresenceUpdated(userId, presence)`: Internal event from stream
  - `TypingStatusUpdated(chatId, typingUsers)`: Internal event from stream
  - `PresenceUnsubscribeRequested(userId)`: Stop watching user
  - `TypingUnsubscribeRequested(chatId)`: Stop watching chat typing

### Stream Management Pattern

All blocs follow this pattern:
1. Store `StreamSubscription` references
2. Cancel existing subscriptions before creating new ones
3. Listen to repository streams and add internal events
4. Clean up all subscriptions in `close()` method

### Usage Example

```dart
// Initialize blocs
final chatBloc = ChatBloc();
final messageBloc = MessageBloc();
final presenceBloc = PresenceBloc();

// Start watching user's chats
chatBloc.add(ChatLoadRequested('user123'));

// Watch messages for a specific chat
messageBloc.add(MessageLoadRequested('chat123'));

// Track user presence
presenceBloc.add(PresenceLoadRequested('user456'));

// Send typing indicator
presenceBloc.add(TypingStarted(userId: 'user123', chatId: 'chat123'));

// Clean up when done (automatic)
// All subscriptions canceled in bloc.close()
```

### Data Sources

- `ChatRemoteDataSource`: Firestore integration for chats, messages, and presence
- `ChatRepository`: Wraps data source with Either<Failure, T> pattern
- `UseCases`: Thin wrappers around repository for business logic isolation

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
