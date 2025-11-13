# Chat Feature Implementation Guide

## Overview

This document describes the chat and presence system integration for the ParcelAm app. The implementation includes:

1. **Routes**: Added `Routes.chatsList` and `Routes.chat` to the routing system
2. **Protected Routes**: Both chat routes are protected by `AuthGuard` 
3. **Dashboard Integration**: Chat icon button with real-time unread message badge
4. **Presence System**: Real-time user online/offline status with app lifecycle management
5. **Notifications**: Local notifications for new messages

## Architecture

### Routes (`lib/core/routes/routes.dart`)
```dart
static const String chatsList = '/chatsList';
static const String chat = '/chat';
```

### Route Protection (`lib/core/routes/getx_route_module.dart`)
Both chat routes are protected with `AuthGuard.createProtectedRoute()`:
- `Routes.chatsList` - Shows list of all chats
- `Routes.chat` - Individual chat screen (requires `chatId` and `otherUserId` arguments)

### Screens

#### ChatsListScreen (`lib/features/travellink/presentation/screens/chats_list_screen.dart`)
- Displays all user chats ordered by `lastMessageTime`
- Shows online status with green indicator
- Displays unread message count badge
- Real-time updates via Firestore streams
- Empty state for no messages

#### ChatScreen (`lib/features/travellink/presentation/screens/chat_screen.dart`)
- One-on-one messaging interface
- Real-time message updates
- Shows user online/offline status and last seen time
- Auto-marks messages as read when opened
- Message bubbles with timestamps

### Services

#### PresenceService (`lib/core/services/presence_service.dart`)
Manages user online/offline presence:
- **Lifecycle Observer**: Implements `WidgetsBindingObserver`
- **Online**: Sets `presence.isOnline = true` when app is active/resumed
- **Offline**: Sets `presence.isOnline = false` and updates `presence.lastSeen` when app is paused/inactive
- **Auto-cleanup**: Sets user offline on dispose

#### ChatNotificationService (`lib/core/services/chat_notification_service.dart`)
Manages local notifications for new messages:
- Listens to all chats where user is a participant
- Shows notification when `unreadCount` increases
- Displays sender name and message preview
- Tappable notification payload includes `chatId`

### Dashboard Integration (`dashboard_screen.dart`)

#### Chat Button with Unread Badge
```dart
class _ChatButton extends StatelessWidget {
  // StreamBuilder monitors all user chats
  // Calculates total unread count across all chats
  // Shows badge with count (9+ if more than 9)
  // Navigates to Routes.chatsList on tap
}
```

#### Initialization in DashboardScreen
```dart
void _initializePresenceAndChatNotifications() {
  // Initialize PresenceService for online/offline tracking
  _presenceService = PresenceService(firestore: sl<FirebaseFirestore>());
  _presenceService.initialize(userId);

  // Initialize ChatNotificationService for message notifications
  _chatNotificationService = ChatNotificationService(...);
  _chatNotificationService.initialize(userId);
  _chatNotificationService.requestPermissions();
}
```

## Firestore Data Structure

### Chat Document (`chats/{chatId}`)
```json
{
  "participants": ["userId1", "userId2"],
  "lastMessage": "Hello!",
  "lastMessageTime": Timestamp,
  "unreadCount": {
    "userId1": 0,
    "userId2": 3
  }
}
```

### Message Document (`chats/{chatId}/messages/{messageId}`)
```json
{
  "senderId": "userId",
  "text": "Message text",
  "timestamp": Timestamp,
  "read": false
}
```

### User Presence (`users/{userId}`)
```json
{
  "presence": {
    "isOnline": true,
    "lastSeen": Timestamp
  }
}
```

## Dependencies

Added to `pubspec.yaml`:
```yaml
flutter_local_notifications: ^18.0.1
```

Existing dependencies used:
- `cloud_firestore` - Real-time database
- `firebase_core` - Firebase initialization
- `get` - Navigation
- `provider` - State management

## Usage

### Navigate to Chats List
```dart
sl<NavigationService>().navigateTo(Routes.chatsList);
```

### Navigate to Specific Chat
```dart
sl<NavigationService>().navigateTo(
  Routes.chat,
  arguments: {
    'chatId': 'chat123',
    'otherUserId': 'user456'
  },
);
```

## Features

✅ Protected routes with AuthGuard  
✅ Real-time chat list with unread badges  
✅ One-on-one messaging  
✅ Online/offline presence tracking  
✅ App lifecycle-based presence updates  
✅ Local notifications for new messages  
✅ Dashboard integration with unread count badge  
✅ Auto-mark messages as read  
✅ Last seen timestamps  
✅ Empty states and error handling  

## Testing

Run the chat integration tests:
```bash
flutter test test/features/chat/chat_integration_test.dart
```

## Next Steps

1. **Permissions**: Ensure notification permissions are requested on app launch
2. **FCM Integration**: Add Firebase Cloud Messaging for background notifications
3. **Image/Media**: Extend messages to support images and files
4. **Read Receipts**: Add double-check marks for read messages
5. **Typing Indicators**: Show when other user is typing
6. **Push Notifications**: Backend integration for push notifications when app is closed
7. **Chat Creation**: Add UI to start new chats with other users
8. **Group Chats**: Extend to support multi-user conversations
