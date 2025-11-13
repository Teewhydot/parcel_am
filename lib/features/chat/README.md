# Chat Feature

A comprehensive real-time chat feature with chat list management, presence indicators, and user discovery.

## Features

### ✅ ChatsListScreen
- **Real-time chat list** with BlocBuilder subscribed to ChatBloc stream
- **Last message preview** with formatted timestamp using `timeago`
- **Unread count badges** displayed for unread messages
- **Real-time presence indicators** (online/offline/typing) for each chat
- **Swipe-to-delete** functionality using `flutter_slidable`
- **Long-press context menu** with options:
  - Pin/Unpin chat
  - Mute/Unmute notifications
  - Mark as read
  - Delete chat
- **Search/Filter functionality** to find chats by name or message content
- **Floating action button** to start new chats with user selection dialog
- **Pull-to-refresh** to manually reload chat list

### Presence Status
- **Online**: Green indicator - user is active
- **Offline**: Gray indicator - user is not online
- **Typing**: Blue indicator with animation - user is typing

### UI Components
- **ChatListItem**: Individual chat tile with avatar, name, last message, timestamp, unread badge
- **PresenceIndicator**: Real-time status indicator widget
- **UserSelectionDialog**: Search and select users to start new conversations

## Architecture

Follows Clean Architecture pattern:

```
lib/features/chat/
├── data/
│   ├── datasources/
│   │   └── chat_remote_datasource.dart
│   ├── models/
│   │   ├── chat_model.dart
│   │   └── user_model.dart
│   └── repositories/
│       └── chat_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── chat_entity.dart
│   │   └── user_entity.dart
│   ├── repositories/
│   │   └── chat_repository.dart
│   └── usecases/
│       └── chat_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── chat_bloc.dart
    │   ├── chat_event.dart
    │   └── chat_data.dart
    ├── screens/
    │   ├── chats_list_screen.dart
    │   └── chat_screen_example.dart
    └── widgets/
        ├── chat_list_item.dart
        ├── presence_indicator.dart
        └── user_selection_dialog.dart
```

## Dependencies

The following packages are used:
- `flutter_bloc` - State management
- `cloud_firestore` - Real-time database
- `flutter_slidable` - Swipe actions
- `timeago` - Relative time formatting
- `get_it` - Dependency injection

## Usage

### 1. Initialize Dependencies

Dependencies are already registered in `lib/injection_container.dart`.

### 2. Use in Your App

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:parcel_am/features/chat/presentation/screens/chats_list_screen.dart';
import 'package:parcel_am/injection_container.dart' as di;

// In your navigation or screen
BlocProvider(
  create: (context) => di.sl<ChatBloc>(),
  child: ChatsListScreen(currentUserId: 'user123'),
);
```

### 3. Firestore Data Structure

#### Chats Collection
```json
{
  "chats": {
    "chatId": {
      "participants": ["userId1", "userId2"],
      "participantId": "userId2",
      "participantName": "John Doe",
      "participantAvatar": "https://...",
      "lastMessage": "Hey, how are you?",
      "lastMessageTime": Timestamp,
      "unreadCount": 3,
      "presenceStatus": "online",
      "isPinned": false,
      "isMuted": false,
      "createdAt": Timestamp
    }
  }
}
```

#### Users Collection (for presence)
```json
{
  "users": {
    "userId": {
      "displayName": "John Doe",
      "photoURL": "https://...",
      "email": "john@example.com",
      "presenceStatus": "online",
      "isOnline": true
    }
  }
}
```

## BLoC Events

- `ChatLoadRequested(userId)` - Load chat list for user
- `ChatDeleteRequested(chatId)` - Delete a chat
- `ChatMarkAsReadRequested(chatId)` - Mark chat as read
- `ChatTogglePinRequested(chatId, isPinned)` - Pin/unpin chat
- `ChatToggleMuteRequested(chatId, isMuted)` - Mute/unmute chat
- `ChatSearchUsersRequested(query)` - Search for users
- `ChatCreateRequested(currentUserId, participantId)` - Create new chat
- `ChatFilterChanged(filter)` - Filter existing chats

## Customization

### Change Colors
Edit `lib/core/theme/app_colors.dart` to customize the color scheme.

### Modify Chat Item UI
Edit `lib/features/chat/presentation/widgets/chat_list_item.dart`.

### Add More Context Menu Options
Edit the `_showContextMenu` method in `chats_list_screen.dart`.

## Future Enhancements

- [ ] Add chat detail screen with messages
- [ ] Implement message sending and receiving
- [ ] Add image/file sharing
- [ ] Voice messages
- [ ] Message reactions
- [ ] Group chats
- [ ] End-to-end encryption
- [ ] Push notifications for new messages
- [ ] Chat archiving
- [ ] Message search within conversations
