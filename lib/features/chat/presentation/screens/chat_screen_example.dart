// Example usage of ChatScreen with BLoC provider

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/chat_bloc.dart';
import 'chat_screen.dart';

/// Example of how to navigate to ChatScreen with proper BLoC setup
class ChatScreenExample extends StatelessWidget {
  const ChatScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Example: Navigate to chat screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => di.sl<ChatBloc>(),
                  child: const ChatScreen(
                    chatId: 'chat_123',
                    otherUserId: 'user_456',
                    otherUserName: 'John Doe',
                    otherUserAvatar: 'https://example.com/avatar.jpg',
                  ),
                ),
              ),
            );
          },
          child: const Text('Open Chat'),
        ),
      ),
    );
  }
}

/// Example of multiple chat conversations list
class ChatListExample extends StatelessWidget {
  const ChatListExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample chat data
    final chats = [
      {
        'chatId': 'chat_1',
        'userId': 'user_1',
        'name': 'Alice Johnson',
        'avatar': null,
        'lastMessage': 'Hey! How are you?',
        'time': '10:30 AM',
      },
      {
        'chatId': 'chat_2',
        'userId': 'user_2',
        'name': 'Bob Smith',
        'avatar': null,
        'lastMessage': 'See you tomorrow!',
        'time': 'Yesterday',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text((chat['name'] as String)[0]),
            ),
            title: Text(chat['name'] as String),
            subtitle: Text(chat['lastMessage'] as String),
            trailing: Text(
              chat['time'] as String,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<ChatBloc>(),
                    child: ChatScreen(
                      chatId: chat['chatId'] as String,
                      otherUserId: chat['userId'] as String,
                      otherUserName: chat['name'] as String,
                      otherUserAvatar: chat['avatar'] as String?,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to new chat screen
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}
