# Chat Feature Integration Guide

## Overview

The ChatsListScreen is a complete real-time chat list implementation with all requested features including real-time updates, presence indicators, swipe actions, and user discovery.

## Features Implemented

### ✅ Real-time Chat List
- **BlocBuilder** subscribed to ChatBloc stream for automatic updates
- **Real-time synchronization** with Firestore
- **Automatic state management** using Clean Architecture + BLoC pattern

### ✅ Message Preview & Timestamps
- **Last message preview** displayed in each chat item
- **Relative timestamps** using `timeago` package (e.g., "2m ago", "1h ago")
- **Unread count badges** prominently displayed

### ✅ Presence Indicators
- **Online**: Green dot indicator
- **Offline**: Gray dot indicator  
- **Typing**: Blue animated indicator
- Real-time updates from Firestore user collection

### ✅ Swipe & Context Actions
- **Swipe-to-delete**: Right swipe reveals actions
  - Pin/Unpin chat
  - Mute/Unmute notifications
  - Delete chat
- **Long-press context menu**: Bottom sheet with all actions
- **Confirmation dialogs** for destructive actions

### ✅ Search & Filter
- **Live filtering** of chats by participant name or message content
- **Search toggle** in app bar
- **Real-time filter updates** as user types

### ✅ New Chat Creation
- **Floating action button** to initiate new chat
- **User selection dialog** with search functionality
- **Automatic chat creation** or navigation to existing chat

## File Structure

```
lib/features/chat/
├── data/
│   ├── datasources/
│   │   └── chat_remote_datasource.dart          # Firebase Firestore operations
│   ├── models/
│   │   ├── chat_model.dart                      # Data model with Firestore serialization
│   │   └── user_model.dart                      # User model for search
│   └── repositories/
│       └── chat_repository_impl.dart            # Repository implementation
├── domain/
│   ├── entities/
│   │   ├── chat_entity.dart                     # Chat domain entity
│   │   └── user_entity.dart                     # User domain entity
│   ├── repositories/
│   │   └── chat_repository.dart                 # Repository interface
│   └── usecases/
│       └── chat_usecase.dart                    # Business logic use cases
└── presentation/
    ├── bloc/
    │   ├── chat_bloc.dart                       # State management
    │   ├── chat_event.dart                      # BLoC events
    │   └── chat_data.dart                       # BLoC state data
    ├── screens/
    │   ├── chats_list_screen.dart              # Main screen (THIS IS IT!)
    │   └── chat_screen_example.dart             # Integration example
    └── widgets/
        ├── chat_list_item.dart                  # Individual chat item widget
        ├── presence_indicator.dart              # Presence status indicator
        └── user_selection_dialog.dart           # User search & selection
```

## Setup Instructions

### 1. Dependencies Already Added

The following packages have been added to `pubspec.yaml`:
```yaml
dependencies:
  flutter_slidable: ^3.1.1  # For swipe actions
  timeago: ^3.7.0           # For relative timestamps
```

Run to install:
```bash
flutter pub get
```

### 2. Dependency Injection

All dependencies are registered in `lib/injection_container.dart`:
- ChatRemoteDataSource
- ChatRepository  
- ChatUseCase
- ChatBloc

### 3. Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:parcel_am/features/chat/presentation/screens/chats_list_screen.dart';
import 'package:parcel_am/injection_container.dart' as di;

// In your app's routing/navigation:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/chats': (context) => BlocProvider(
              create: (context) => di.sl<ChatBloc>(),
              child: ChatsListScreen(
                currentUserId: 'your-user-id-here', // Get from auth
              ),
            ),
      },
    );
  }
}

// Or push directly:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => di.sl<ChatBloc>(),
      child: ChatsListScreen(
        currentUserId: currentUserId,
      ),
    ),
  ),
);
```

### 4. Firestore Data Structure

#### Create Firestore Collections

**chats** collection:
```javascript
{
  "chatId": {
    "participants": ["userId1", "userId2"],
    "participantId": "userId2",
    "participantName": "John Doe",
    "participantAvatar": "https://example.com/avatar.jpg",
    "lastMessage": "Hey, how are you?",
    "lastMessageTime": Timestamp(2024, 1, 15, 10, 30),
    "unreadCount": 3,
    "presenceStatus": "online",  // or "offline", "typing"
    "isPinned": false,
    "isMuted": false,
    "createdAt": Timestamp(2024, 1, 10)
  }
}
```

**users** collection (for presence and search):
```javascript
{
  "userId": {
    "displayName": "John Doe",
    "photoURL": "https://example.com/avatar.jpg",
    "email": "john@example.com",
    "presenceStatus": "online",
    "isOnline": true,
    "lastSeen": Timestamp(2024, 1, 15, 10, 30)
  }
}
```

#### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Chats collection
    match /chats/{chatId} {
      allow read: if request.auth != null && 
                  request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                             request.auth.uid in resource.data.participants;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Firestore Indexes

Create a composite index for efficient queries:
- Collection: `chats`
- Fields: 
  - `participants` (Array)
  - `lastMessageTime` (Descending)

## BLoC Events Reference

```dart
// Load chat list
context.read<ChatBloc>().add(ChatLoadRequested('userId'));

// Delete chat
context.read<ChatBloc>().add(ChatDeleteRequested('chatId'));

// Mark as read
context.read<ChatBloc>().add(ChatMarkAsReadRequested('chatId'));

// Pin/unpin
context.read<ChatBloc>().add(ChatTogglePinRequested('chatId', true));

// Mute/unmute
context.read<ChatBloc>().add(ChatToggleMuteRequested('chatId', true));

// Search users
context.read<ChatBloc>().add(ChatSearchUsersRequested('query'));

// Create new chat
context.read<ChatBloc>().add(
  ChatCreateRequested('currentUserId', 'participantId')
);

// Filter chats
context.read<ChatBloc>().add(ChatFilterChanged('filter text'));
```

## Customization

### Modify Colors
Edit `lib/core/theme/app_colors.dart`:
```dart
static const Color primary = Color(0xFF1B8B5C);  // Change primary color
static const Color success = Color(0xFF22C55E);  // Change online indicator
```

### Change Avatar Placeholder
Edit `lib/features/chat/presentation/widgets/chat_list_item.dart` line 27-36.

### Customize Swipe Actions
Edit `lib/features/chat/presentation/screens/chats_list_screen.dart` lines 179-213.

### Modify Context Menu
Edit `lib/features/chat/presentation/screens/chats_list_screen.dart` lines 280-330.

## Testing

Tests are provided in `test/features/chat/presentation/bloc/chat_bloc_test.dart`.

Run tests:
```bash
flutter test test/features/chat/
```

Generate mocks (first time only):
```bash
flutter pub run build_runner build
```

## Next Steps

1. **Run the app**: `flutter run`
2. **Navigate to ChatsListScreen** using your routing system
3. **Create test data** in Firestore using the console
4. **Test features**:
   - View chat list
   - Swipe actions
   - Long-press menu
   - Search functionality
   - Create new chat

## Integration with Existing Features

### With Authentication
```dart
import 'package:firebase_auth/firebase_auth.dart';

final currentUserId = FirebaseAuth.instance.currentUser?.uid;
if (currentUserId != null) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BlocProvider(
        create: (context) => di.sl<ChatBloc>(),
        child: ChatsListScreen(currentUserId: currentUserId),
      ),
    ),
  );
}
```

### Add to Bottom Navigation
```dart
BottomNavigationBarItem(
  icon: Icon(Icons.chat),
  label: 'Chats',
)

// In body:
if (currentIndex == 2) // Chats tab
  BlocProvider(
    create: (context) => di.sl<ChatBloc>(),
    child: ChatsListScreen(currentUserId: currentUserId),
  )
```

## Troubleshooting

### No chats showing
- Check Firestore security rules
- Verify user ID is correct
- Check `participants` array includes current user

### Presence not updating
- Ensure users collection exists
- Update `presenceStatus` field when user logs in/out
- Check Firestore listeners are active

### Swipe actions not working
- Ensure `flutter_slidable` is installed
- Check key is unique (line 179 in chats_list_screen.dart)

## Support & Documentation

- Full feature documentation: `lib/features/chat/README.md`
- Clean Architecture guide: `AGENTS.md`
- Project structure: Follow existing patterns in `lib/features/`

## Future Enhancements

Ready to add:
- Chat detail screen with messages
- Message sending/receiving
- Image/file sharing
- Voice messages
- Push notifications
- Group chats
- Message reactions
