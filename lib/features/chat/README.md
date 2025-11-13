# Chat Feature

A complete real-time chat implementation using Firebase and Clean Architecture with BLoC pattern.

## Features

### ✅ Implemented

- **Real-time messaging** with Firestore streams
- **Message types support:**
  - Text messages with emoji support
  - Image messages with tap-to-view
  - Video messages with thumbnail preview
  - Document messages with download capability
- **Rich UI components:**
  - Message bubbles with proper styling
  - Reply-to-message with swipe gesture support
  - Typing indicators with animation
  - Online/offline status in app bar
  - Read receipts and delivery status
- **Media handling:**
  - Image picker integration (camera/gallery)
  - Video picker from gallery
  - Firebase Storage upload with progress tracking
  - Automatic file size formatting
- **User experience:**
  - Auto-scroll to bottom on new messages
  - Mark messages as read automatically
  - Last seen timestamp display
  - Upload progress indicator
  - Empty state UI
  - Message deletion support

## Architecture

```
lib/features/chat/
├── data/
│   ├── datasources/
│   │   └── chat_remote_data_source.dart      # Firebase operations
│   ├── models/
│   │   ├── chat_model.dart                   # Chat data model
│   │   └── message_model.dart                # Message data model
│   └── repositories/
│       └── chat_repository_impl.dart         # Repository implementation
├── domain/
│   ├── entities/
│   │   ├── chat.dart                         # Chat entity
│   │   └── message.dart                      # Message entity
│   ├── repositories/
│   │   └── chat_repository.dart              # Repository interface
│   └── usecases/
│       └── chat_usecase.dart                 # Business logic
└── presentation/
    ├── bloc/
    │   ├── chat_bloc.dart                    # BLoC implementation
    │   ├── chat_event.dart                   # Events
    │   └── chat_state.dart                   # States
    ├── screens/
    │   ├── chat_screen.dart                  # Main chat UI
    │   └── chat_screen_example.dart          # Usage examples
    └── widgets/
        ├── message_bubble.dart               # Message display widget
        ├── message_input.dart                # Input field widget
        └── typing_indicator.dart             # Typing animation widget
```

## Usage

### 1. Setup Dependencies

Already registered in `injection_container.dart`:
- `ChatRemoteDataSource`
- `ChatRepository`
- `ChatUseCase`
- `ChatBloc`

### 2. Navigate to Chat Screen

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:parcel_am/features/chat/presentation/screens/chat_screen.dart';
import 'package:parcel_am/injection_container.dart' as di;

// Navigate to chat
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => di.sl<ChatBloc>(),
      child: ChatScreen(
        chatId: 'chat_123',
        otherUserId: 'user_456',
        otherUserName: 'John Doe',
        otherUserAvatar: 'https://example.com/avatar.jpg',
      ),
    ),
  ),
);
```

### 3. Firebase Firestore Structure

```
chats/{chatId}
  ├── id: string
  ├── participantIds: [string]
  ├── participantNames: {userId: name}
  ├── participantAvatars: {userId: url}
  ├── lastMessage: Message
  ├── lastMessageTime: Timestamp
  ├── unreadCount: {userId: number}
  ├── isTyping: {userId: boolean}
  ├── lastSeen: {userId: Timestamp}
  └── createdAt: Timestamp
  
  messages/{messageId}
    ├── id: string
    ├── chatId: string
    ├── senderId: string
    ├── senderName: string
    ├── senderAvatar: string?
    ├── content: string
    ├── type: 'text' | 'image' | 'video' | 'document'
    ├── status: 'sending' | 'sent' | 'delivered' | 'read' | 'failed'
    ├── timestamp: Timestamp
    ├── mediaUrl: string?
    ├── thumbnailUrl: string?
    ├── fileName: string?
    ├── fileSize: number?
    ├── replyToMessageId: string?
    ├── isDeleted: boolean
    └── readBy: {userId: Timestamp}
```

### 4. Firebase Storage Structure

```
chats/{chatId}/
  ├── images/{timestamp}-{filename}
  ├── videos/{timestamp}-{filename}
  └── documents/{timestamp}-{filename}
```

## Features in Detail

### Message Types

#### Text Messages
- Support for emoji and text
- Styled message bubbles
- Reply preview display
- Read receipts

#### Image Messages
- Image picker (camera/gallery)
- Cached network images
- Tap to view fullscreen (TODO)
- Optional caption

#### Video Messages
- Video picker from gallery
- Thumbnail preview
- Play button overlay
- Tap to play (TODO)

#### Document Messages
- File attachment support
- File size display
- Download functionality (TODO)
- Document icon

### Real-time Features

#### Typing Indicators
- Animated dots
- Shows when other user is typing
- Automatically cleared after inactivity

#### Online Status
- Real-time online/offline status
- Last seen timestamp
- "typing..." status
- Time ago formatting (e.g., "5m ago", "2h ago")

#### Read Receipts
- Sending: clock icon
- Sent: single check
- Delivered: double check (gray)
- Read: double check (blue)

### Reply to Message

Users can long-press any message to:
- Reply to the message
- Delete their own messages

Reply UI shows:
- Original sender name
- Message preview
- Visual indicator with colored border
- Cancel button

### Media Upload

- Progress indicator during upload
- Disabled input during upload
- Firebase Storage integration
- Automatic URL generation

## Permissions Required

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select photos</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for videos</string>
```

## Testing

Run tests with:
```bash
flutter test lib/features/chat
```

## Future Enhancements

- [ ] Voice messages
- [ ] Message reactions (emoji reactions)
- [ ] Message forwarding
- [ ] Media viewer (fullscreen images/videos)
- [ ] File download manager
- [ ] Push notifications
- [ ] Group chat support
- [ ] Message search
- [ ] Chat backup/export
- [ ] End-to-end encryption

## Dependencies

- `flutter_bloc` - State management
- `firebase_core` - Firebase initialization
- `cloud_firestore` - Real-time database
- `firebase_storage` - File storage
- `firebase_auth` - User authentication
- `image_picker` - Media selection
- `cached_network_image` - Image caching
- `intl` - Date formatting
- `equatable` - Value equality
- `dartz` - Functional programming

## Troubleshooting

### Messages not loading
- Check Firebase Firestore rules
- Verify chatId exists
- Check network connectivity

### Images not uploading
- Verify Firebase Storage rules
- Check file permissions
- Ensure Firebase Storage is enabled

### Typing indicator stuck
- Clear typing status on app background/close
- Implement timeout mechanism

## Contributing

Follow the Clean Architecture pattern:
1. Add entities in `domain/entities/`
2. Update models in `data/models/`
3. Implement in data source
4. Update repository
5. Add use cases
6. Update BLoC events/states
7. Implement UI
