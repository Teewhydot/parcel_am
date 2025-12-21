// Example usage of ChatScreen with navigation service

import 'package:flutter/material.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';

/// Example of how to navigate to ChatScreen with proper BLoC setup
class ChatScreenExample extends StatelessWidget {
  const ChatScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge('Chat Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Example: Navigate to chat screen using navigation service
            sl<NavigationService>().navigateTo(
              Routes.chat,
              arguments: {
                'chatId': 'chat_123',
                'otherUserId': 'user_456',
                'otherUserName': 'John Doe',
                'otherUserAvatar': 'https://example.com/avatar.jpg',
              },
            );
          },
          child: AppText.bodyMedium('Open Chat'),
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
      appBar: AppBar(title: AppText.titleLarge('Chats')),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              child: AppText.bodyMedium((chat['name'] as String)[0]),
            ),
            title: AppText.bodyMedium(chat['name'] as String),
            subtitle: AppText.bodySmall(chat['lastMessage'] as String),
            trailing: AppText(
              chat['time'] as String,
              variant: TextVariant.bodySmall,
              fontSize: 12,
              color: Colors.grey,
            ),
            onTap: () {
              sl<NavigationService>().navigateTo(
                Routes.chat,
                arguments: {
                  'chatId': chat['chatId'] as String,
                  'otherUserId': chat['userId'] as String,
                  'otherUserName': chat['name'] as String,
                  'otherUserAvatar': chat['avatar'],
                },
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
