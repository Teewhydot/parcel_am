import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../travellink/domain/entities/chat/chat_entity.dart';
import '../../../travellink/domain/entities/chat/chat_entity_extensions.dart';
import '../../../travellink/presentation/bloc/chat/chat_bloc.dart';
import '../../../travellink/presentation/bloc/chat/chat_event.dart';
import '../../../travellink/presentation/bloc/chat/chat_data.dart';
import '../widgets/chat_list_item.dart';

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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatLoadRequested(widget.currentUserId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  context.read<ChatBloc>().add(ChatFilterChanged(value));
                },
              )
            : const Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<ChatBloc>().add(const ChatFilterChanged(''));
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                // Navigate to settings
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, BaseState<ChatData>>(
        listener: (context, state) {
          if (state is AsyncErrorState<ChatData>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state is AsyncLoadedState<ChatData> && state.data != null) {
            // Chat created successfully, show message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat created successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LoadingState<ChatData> && state.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AsyncErrorState<ChatData> && state.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ChatBloc>().add(ChatLoadRequested(widget.currentUserId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = state.data ?? const ChatData();
          final chats = data.filteredChats;

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          final pinnedChats = chats.where((chat) => chat.isPinned).toList();
          final regularChats = chats.where((chat) => !chat.isPinned).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ChatBloc>().add(ChatLoadRequested(widget.currentUserId));
            },
            child: ListView(
              children: [
                if (pinnedChats.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'PINNED',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  ...pinnedChats.map((chat) => _buildChatItem(context, chat)),
                  const Divider(height: 1),
                ],
                if (regularChats.isNotEmpty) ...[
                  if (pinnedChats.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'ALL CHATS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ...regularChats.map((chat) => _buildChatItem(context, chat)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserSelectionDialog(context),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, ChatEntity chat) {
    return Slidable(
      key: ValueKey(chat.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              context.read<ChatBloc>().add(
                    ChatTogglePinRequested(chat.id),
                  );
            },
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            icon: chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: chat.isPinned ? 'Unpin' : 'Pin',
          ),
          SlidableAction(
            onPressed: (context) {
              context.read<ChatBloc>().add(
                    ChatToggleMuteRequested(chat.id),
                  );
            },
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            icon: chat.isMuted ? Icons.notifications : Icons.notifications_off,
            label: chat.isMuted ? 'Unmute' : 'Mute',
          ),
          SlidableAction(
            onPressed: (context) {
              _showDeleteConfirmation(context, chat);
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ChatListItem(
        chat: chat,
        currentUserId: widget.currentUserId,
        onTap: () {
          final unreadCount = chat.getUnreadCount(widget.currentUserId);
          if (unreadCount > 0) {
            context.read<ChatBloc>().add(ChatMarkAsReadRequested(chat.id));
          }
          // Navigate to chat detail screen
        },
        onLongPress: () {
          _showContextMenu(context, chat);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatEntity chat) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat with ${chat.participantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatBloc>().add(ChatDeleteRequested(chat.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, ChatEntity chat) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(chat.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                context.read<ChatBloc>().add(
                      ChatTogglePinRequested(chat.id),
                    );
                Navigator.pop(bottomSheetContext);
              },
            ),
            ListTile(
              leading: Icon(chat.isMuted ? Icons.notifications : Icons.notifications_off),
              title: Text(chat.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                context.read<ChatBloc>().add(
                      ChatToggleMuteRequested(chat.id),
                    );
                Navigator.pop(bottomSheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Mark as Read'),
              onTap: () {
                context.read<ChatBloc>().add(ChatMarkAsReadRequested(chat.id));
                Navigator.pop(bottomSheetContext);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Chat', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showDeleteConfirmation(context, chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserSelectionDialog(BuildContext context) {
    // TODO: Implement user selection dialog with proper ChatBloc integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User selection not yet implemented')),
    );
  }
}
