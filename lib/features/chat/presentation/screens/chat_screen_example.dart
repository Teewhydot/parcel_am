import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/chat_bloc.dart';
import 'chats_list_screen.dart';

/// Example of how to integrate ChatsListScreen
/// Use this as reference for adding to your navigation/routing system
class ChatScreenExample extends StatelessWidget {
  final String currentUserId;

  const ChatScreenExample({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ChatBloc>(),
      child: ChatsListScreen(currentUserId: currentUserId),
    );
  }
}
