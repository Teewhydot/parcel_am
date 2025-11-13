# Chat Feature - Data Layer Implementation

This directory contains the complete data layer implementation for the chat feature using Firebase Firestore and Firebase Storage.

## Architecture

The implementation follows Clean Architecture principles with the following structure:

```
chat/
├── data/
│   ├── datasources/        # Remote data sources for Firebase operations
│   ├── models/            # Data models with Firestore converters
│   └── repositories/      # Repository implementations
└── domain/
    ├── entities/          # Domain entities
    └── repositories/      # Repository interfaces
```

## Components

### Domain Layer

#### Entities
- **ChatEntity**: Represents a chat conversation with participants, last message info, unread counts
- **MessageEntity**: Represents individual messages with content, type (text/image/document/video), status
- **PresenceEntity**: Represents user online/offline/typing status with last seen timestamp

#### Repositories (Interfaces)
- **ChatRepository**: Defines chat operations
- **MessageRepository**: Defines message operations
- **PresenceRepository**: Defines presence tracking operations

### Data Layer

#### Models
All models include:
- `fromFirestore()` factory for Firestore document deserialization
- `toJson()` method for Firestore document serialization
- `toEntity()` method to convert to domain entities
- `fromEntity()` factory to convert from domain entities

**ChatModel**:
- Converts Firestore timestamps to DateTime
- Handles nested unreadCount map
- Manages participantInfo metadata

**MessageModel**:
- Supports multiple message types (text, image, document, video)
- Tracks message status (sending, sent, delivered, read, failed)
- Handles file attachments with URLs and metadata

**PresenceModel**:
- Tracks user online/offline/away status
- Manages typing indicators per chat
- Records last seen timestamps

#### Data Sources

**ChatRemoteDataSource**:
- `watchUserChats()`: Real-time stream of user's chats
- `watchChat()`: Real-time stream of specific chat
- `createChat()`: Create new chat with participants
- `updateChat()`: Update chat metadata
- `deleteChat()`: Delete chat
- `markMessagesAsRead()`: Mark all messages as read for a user
- `getChatByParticipants()`: Find existing chat by participants

**MessageRemoteDataSource**:
- `watchMessages()`: Real-time stream of messages in a chat
- `sendMessage()`: Send new message and update chat
- `updateMessage()`: Update message content/status
- `deleteMessage()`: Soft delete message
- `uploadFile()`: Upload file to Firebase Storage (images/documents/videos)
- `updateMessageStatus()`: Update message delivery status

**PresenceRemoteDataSource**:
- `watchUserPresence()`: Real-time stream of user's presence
- `updatePresenceStatus()`: Update online/offline/away status
- `updateTypingStatus()`: Update typing indicator
- `updateLastSeen()`: Update last seen timestamp
- `getUserPresence()`: Get current presence snapshot

#### Repository Implementations

All repository implementations:
- Check network connectivity before operations
- Wrap operations in Either<Failure, T> for error handling
- Convert data models to domain entities
- Transform streams to Stream<Either<Failure, T>>

**ChatRepositoryImpl**: Implements ChatRepository with error handling
**MessageRepositoryImpl**: Implements MessageRepository with file upload support
**PresenceRepositoryImpl**: Implements PresenceRepository with real-time updates

## Dependency Injection

All components are registered in `lib/injection_container.dart`:

```dart
// Data Sources
sl.registerLazySingleton<ChatRemoteDataSource>(...)
sl.registerLazySingleton<MessageRemoteDataSource>(...)
sl.registerLazySingleton<PresenceRemoteDataSource>(...)

// Repositories
sl.registerLazySingleton<ChatRepository>(...)
sl.registerLazySingleton<MessageRepository>(...)
sl.registerLazySingleton<PresenceRepository>(...)
```

## Firestore Structure

### Collections

**chats/**
```
{
  participantIds: [userId1, userId2],
  participantInfo: { userId1: { name, avatar }, ... },
  lastMessage: "message text",
  lastMessageSenderId: "userId",
  lastMessageAt: Timestamp,
  unreadCount: { userId1: 0, userId2: 3 },
  createdAt: Timestamp,
  updatedAt: Timestamp,
  chatType: "direct" | "group"
}
```

**chats/{chatId}/messages/**
```
{
  chatId: "chatId",
  senderId: "userId",
  content: "message text",
  type: "text" | "image" | "document" | "video",
  status: "sending" | "sent" | "delivered" | "read" | "failed",
  createdAt: Timestamp,
  updatedAt: Timestamp?,
  fileUrl: "https://...",
  fileName: "file.jpg",
  fileSize: 1024,
  isDeleted: false
}
```

**presence/**
```
{
  status: "online" | "offline" | "away",
  lastSeen: Timestamp,
  isTyping: boolean,
  typingInChatId: "chatId",
  lastTypingAt: Timestamp
}
```

## Storage Structure

Files are stored in Firebase Storage:
```
chats/{chatId}/images/{timestamp}-{filename}
chats/{chatId}/documents/{timestamp}-{filename}
chats/{chatId}/videos/{timestamp}-{filename}
```

## Usage Example

```dart
// Get chat repository
final chatRepo = sl<ChatRepository>();

// Watch user chats
chatRepo.watchUserChats(userId).listen((result) {
  result.fold(
    (failure) => print('Error: ${failure.failureMessage}'),
    (chats) => print('Loaded ${chats.length} chats'),
  );
});

// Send message
final messageRepo = sl<MessageRepository>();
final result = await messageRepo.sendMessage(messageEntity);
result.fold(
  (failure) => print('Failed to send'),
  (message) => print('Message sent: ${message.id}'),
);

// Update presence
final presenceRepo = sl<PresenceRepository>();
await presenceRepo.updatePresenceStatus(userId, PresenceStatus.online);
```

## Error Handling

All repository methods return `Either<Failure, T>` where Failure types include:
- `NoInternetFailure`: No network connection
- `ServerFailure`: Firebase/Firestore errors
- `UnknownFailure`: Unexpected errors

Streams emit `Stream<Either<Failure, T>>` for real-time error handling.

## Testing

Basic test structure provided in `test/features/chat/data/models/chat_model_test.dart`.

Add more tests for:
- Repository implementations with mocked data sources
- Data source implementations with mocked Firestore
- Model conversions (toJson/fromFirestore/toEntity)

## Dependencies

- `cloud_firestore`: Firestore database operations
- `firebase_storage`: File upload/download
- `dartz`: Functional programming (Either type)
- `equatable`: Value equality for entities
