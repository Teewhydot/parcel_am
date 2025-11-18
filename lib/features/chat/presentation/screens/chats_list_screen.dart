import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../domain/entities/chat.dart';
import '../bloc/chats_list_bloc.dart';

class ChatsListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatsListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late ChatsListBloc _chatsListBloc;

  @override
  void initState() {
    super.initState();
    _chatsListBloc = ChatsListBloc();
    _chatsListBloc.add(LoadChats(widget.currentUserId));
  }

  @override
  void dispose() {
    _chatsListBloc.close();
    super.dispose();
  }

  String _getOtherParticipantName(Chat chat) {
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
    return chat.participantNames[otherParticipantId] ?? 'Unknown';
  }

  String? _getOtherParticipantAvatar(Chat chat) {
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
    return chat.participantAvatars[otherParticipantId];
  }

  String _getOtherParticipantId(Chat chat) {
    return chat.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
  }

  int _getUnreadCount(Chat chat) {
    return chat.unreadCount[widget.currentUserId] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ChatsListBloc, BaseState<List<Chat>>>(
        bloc: _chatsListBloc,
        builder: (context, state) {
          if (state is LoadingState<List<Chat>>) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ErrorState<List<Chat>>) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _chatsListBloc.add(LoadChats(widget.currentUserId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is LoadedState<List<Chat>>) {
            final chats = state.data ?? [];

            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No chats yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation with someone',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _chatsListBloc.add(LoadChats(widget.currentUserId));
              },
              child: ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final otherParticipantName = _getOtherParticipantName(chat);
                  final otherParticipantAvatar = _getOtherParticipantAvatar(chat);
                  final otherParticipantId = _getOtherParticipantId(chat);
                  final unreadCount = _getUnreadCount(chat);
                  final isTyping = chat.isTyping[otherParticipantId] ?? false;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      backgroundImage: otherParticipantAvatar != null
                          ? NetworkImage(otherParticipantAvatar)
                          : null,
                      child: otherParticipantAvatar == null
                          ? Text(
                              otherParticipantName.isNotEmpty
                                  ? otherParticipantName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      otherParticipantName,
                      style: TextStyle(
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      isTyping
                          ? 'typing...'
                          : chat.lastMessage?.content ?? 'No messages yet',
                      style: TextStyle(
                        color: isTyping ? AppColors.primary : Colors.grey[600],
                        fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (chat.lastMessageTime != null)
                          Text(
                            _formatTime(chat.lastMessageTime!),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      Get.toNamed(
                        Routes.chat,
                        arguments: {
                          'chatId': chat.id,
                          'otherUserId': otherParticipantId,
                          'otherUserName': otherParticipantName,
                          'otherUserAvatar': otherParticipantAvatar,
                        },
                      );
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return _getDayName(time.weekday);
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
