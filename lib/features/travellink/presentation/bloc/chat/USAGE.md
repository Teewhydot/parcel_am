# Chat BLoC Usage Guide

## Overview

This document explains how to use the Chat, Message, and Presence BLoCs with real-time stream management.

## Features

### 1. ChatBloc - Real-time Chat List

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/chat/chat_exports.dart';

// Provide the bloc
BlocProvider(
  create: (context) => ChatBloc()..add(ChatLoadRequested('currentUserId')),
  child: ChatListScreen(),
)

// Listen to chat updates in UI
BlocConsumer<ChatBloc, BaseState<ChatData>>(
  listener: (context, state) {
    if (state is AsyncErrorState<ChatData>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage)),
      );
    }
  },
  builder: (context, state) {
    if (state.isLoading && !state.hasData) {
      return CircularProgressIndicator();
    }
    
    final chats = state.data?.chats ?? [];
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) => ChatTile(chat: chats[index]),
    );
  },
)

// Create a new chat
context.read<ChatBloc>().add(
  ChatCreateRequested(['user1', 'user2']),
);

// Mark chat as read
context.read<ChatBloc>().add(
  ChatMarkAsRead('chatId', 'userId'),
);
```

### 2. MessageBloc - Per-Chat Message Streams

```dart
// Provide the bloc (typically at app root for multi-chat support)
BlocProvider(
  create: (context) => MessageBloc(),
  child: MyApp(),
)

// Start watching messages for a chat
context.read<MessageBloc>().add(
  MessageLoadRequested('chatId'),
);

// Display messages
BlocBuilder<MessageBloc, BaseState<MessageData>>(
  builder: (context, state) {
    final messages = state.data?.getMessages('chatId') ?? [];
    
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(message: message);
      },
    );
  },
)

// Send a message
context.read<MessageBloc>().add(
  MessageSendRequested(
    chatId: 'chatId',
    senderId: 'userId',
    content: 'Hello!',
    type: MessageType.text,
  ),
);

// Delete a message
context.read<MessageBloc>().add(
  MessageDeleteRequested('messageId'),
);

// Stop watching a chat (when leaving chat screen)
context.read<MessageBloc>().add(
  MessageUnsubscribeRequested('chatId'),
);
```

### 3. PresenceBloc - Online Status & Typing Indicators

```dart
// Provide the bloc
BlocProvider(
  create: (context) => PresenceBloc(),
  child: MyApp(),
)

// Watch user presence
context.read<PresenceBloc>().add(
  PresenceLoadRequested('otherUserId'),
);

// Display online status
BlocBuilder<PresenceBloc, BaseState<PresenceData>>(
  builder: (context, state) {
    final presence = state.data?.getPresence('otherUserId');
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: presence?.status == OnlineStatus.online
                ? Colors.green
                : Colors.grey,
          ),
        ),
        SizedBox(width: 4),
        Text(presence?.status.name ?? 'offline'),
      ],
    );
  },
)

// Update own presence
context.read<PresenceBloc>().add(
  PresenceUpdateRequested(
    userId: 'currentUserId',
    status: OnlineStatus.online,
    currentChatId: 'chatId',
  ),
);

// Show typing indicator
BlocBuilder<PresenceBloc, BaseState<PresenceData>>(
  builder: (context, state) {
    final typingUsers = state.data?.getTypingStatus('chatId') ?? {};
    final isTyping = typingUsers.values.any((typing) => typing);
    
    if (isTyping) {
      return Text('Someone is typing...');
    }
    return SizedBox.shrink();
  },
)

// Start typing
final textController = TextEditingController();
textController.addListener(() {
  if (textController.text.isNotEmpty) {
    context.read<PresenceBloc>().add(
      TypingStarted(userId: 'currentUserId', chatId: 'chatId'),
    );
  } else {
    context.read<PresenceBloc>().add(
      TypingEnded(userId: 'currentUserId', chatId: 'chatId'),
    );
  }
});

// Cleanup
@override
void dispose() {
  // Blocs automatically clean up subscriptions on close()
  // But you can manually unsubscribe if needed
  context.read<MessageBloc>().add(
    MessageUnsubscribeRequested('chatId'),
  );
  super.dispose();
}
```

## Complete Chat Screen Example

```dart
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatScreen({
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    
    // Start watching messages
    context.read<MessageBloc>().add(
      MessageLoadRequested(widget.chatId),
    );
    
    // Update presence
    context.read<PresenceBloc>().add(
      PresenceUpdateRequested(
        userId: widget.currentUserId,
        status: OnlineStatus.online,
        currentChatId: widget.chatId,
      ),
    );
    
    // Setup typing listener
    _messageController.addListener(_onTyping);
  }

  void _onTyping() {
    if (_messageController.text.isNotEmpty) {
      context.read<PresenceBloc>().add(
        TypingStarted(
          userId: widget.currentUserId,
          chatId: widget.chatId,
        ),
      );
      
      // Auto-stop typing after 3 seconds
      _typingTimer?.cancel();
      _typingTimer = Timer(Duration(seconds: 3), () {
        context.read<PresenceBloc>().add(
          TypingEnded(
            userId: widget.currentUserId,
            chatId: widget.chatId,
          ),
        );
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    context.read<MessageBloc>().add(
      MessageSendRequested(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: _messageController.text.trim(),
      ),
    );
    
    context.read<PresenceBloc>().add(
      TypingEnded(
        userId: widget.currentUserId,
        chatId: widget.chatId,
      ),
    );
    
    _messageController.clear();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    
    // Unsubscribe from messages
    context.read<MessageBloc>().add(
      MessageUnsubscribeRequested(widget.chatId),
    );
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<PresenceBloc, BaseState<PresenceData>>(
          builder: (context, state) {
            final presence = state.data?.getPresence('otherUserId');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat'),
                Text(
                  presence?.status == OnlineStatus.online
                      ? 'Online'
                      : 'Offline',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocBuilder<MessageBloc, BaseState<MessageData>>(
              builder: (context, state) {
                final messages = state.data?.getMessages(widget.chatId) ?? [];
                
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == widget.currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          
          // Typing indicator
          BlocBuilder<PresenceBloc, BaseState<PresenceData>>(
            builder: (context, state) {
              final typingUsers = state.data?.getTypingStatus(widget.chatId) ?? {};
              final othersTyping = typingUsers.entries
                  .where((e) => e.key != widget.currentUserId && e.value)
                  .isNotEmpty;
              
              if (othersTyping) {
                return Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Typing...', style: TextStyle(fontSize: 12)),
                );
              }
              return SizedBox.shrink();
            },
          ),
          
          // Input field
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Stream Lifecycle

### Automatic Cleanup
All blocs implement proper cleanup in their `close()` method:

```dart
@override
Future<void> close() {
  // Cancel all active subscriptions
  _subscriptions.forEach((key, sub) => sub.cancel());
  _subscriptions.clear();
  return super.close();
}
```

### Manual Subscription Management
For MessageBloc, you can manually unsubscribe from specific chats:

```dart
// When navigating away from a chat
messageBloc.add(MessageUnsubscribeRequested('chatId'));
```

## Testing

See test files for examples:
- `chat_bloc_test.dart`
- `message_bloc_test.dart`
- `presence_bloc_test.dart`

## Architecture Notes

1. **Stream-to-Event Pattern**: Streams emit Either<Failure, Data>, which are converted to internal events
2. **Multi-Subscription Support**: MessageBloc and PresenceBloc support multiple concurrent subscriptions
3. **Automatic Updates**: All Firestore changes automatically trigger state updates
4. **Error Handling**: Stream errors are caught and converted to error states
5. **Clean Architecture**: Clear separation between domain, data, and presentation layers
