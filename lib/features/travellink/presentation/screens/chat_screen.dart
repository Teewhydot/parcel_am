import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../injection_container.dart' as di;
import '../../../chat/domain/entities/message.dart';
import '../../../chat/domain/entities/message_type.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/bloc/chat_event.dart';
import '../../../chat/presentation/bloc/chat_state.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _chatBloc = di.sl<ChatBloc>();
    _initializeChat();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
    _currentUserName = user?.displayName ?? 'You';
    _currentUserAvatar = user?.photoURL;
  }

  void _initializeChat() {
    _chatBloc.add(LoadMessages(widget.chatId));
    _chatBloc.add(LoadChat(widget.chatId));
    _updateLastSeen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _updateLastSeen();
    _chatBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateLastSeen();
    } else if (state == AppLifecycleState.resumed) {
      _updateLastSeen();
    }
  }

  void _updateLastSeen() {
    if (_currentUserId != null) {
      _chatBloc.add(
        UpdateLastSeen(chatId: widget.chatId, userId: _currentUserId!),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    _messageController.clear();

    final message = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'You',
      senderAvatar: _currentUserAvatar,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    _chatBloc.add(SendMessage(message));

    // Scroll after a brief delay to allow message to be added
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _handleTyping(bool isTyping) {
    if (_currentUserId != null) {
      _chatBloc.add(
        SetTypingStatus(
          chatId: widget.chatId,
          userId: _currentUserId!,
          isTyping: isTyping,
        ),
      );
    }
  }

  void _markMessagesAsRead(List<Message> messages) {
    if (_currentUserId == null) return;

    for (final message in messages) {
      if (message.senderId != _currentUserId &&
          message.status != MessageStatus.read) {
        _chatBloc.add(
          MarkMessageAsRead(
            chatId: widget.chatId,
            messageId: message.id,
            userId: _currentUserId!,
          ),
        );
      }
    }
  }

  String _getOnlineStatus(MessagesLoaded state) {
    if (state.chat == null) return 'Offline';

    final isTyping = state.chat!.isTyping[widget.otherUserId] ?? false;
    if (isTyping) return 'typing...';

    final lastSeen = state.chat!.lastSeen[widget.otherUserId];
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) return 'Online';
    if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return 'Last seen ${difference.inHours}h ago';
    }
    return 'Last seen ${difference.inDays}d ago';
  }

  String _getOtherUserName(MessagesLoaded state) {
    // Try to get name from chat metadata if available
    // Otherwise, fall back to a default
    return 'User';
  }

  bool _isOnline(MessagesLoaded state) {
    if (state.chat == null) return false;

    final lastSeen = state.chat!.lastSeen[widget.otherUserId];
    if (lastSeen == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    return difference.inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: AppScaffold(
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AppContainer(
                variant: ContainerVariant.surface,
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Column(
                  children: [
                    Expanded(child: _buildMessagesList()),
                    _buildMessageInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppContainer(
      padding: AppSpacing.paddingXL,
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final displayName = state is MessagesLoaded
              ? _getOtherUserName(state)
              : 'User';
          final status = state is MessagesLoaded
              ? _getOnlineStatus(state)
              : 'Offline';
          final isOnline = state is MessagesLoaded
              ? _isOnline(state)
              : false;

          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(
                      displayName,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    AppText.bodySmall(
                      status,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is MessageSent) {
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        } else if (state is MessagesLoaded) {
          _markMessagesAsRead(state.messages);
        }
      },
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MessagesLoaded) {
          final messages = state.messages;

          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.md),
                  AppText.bodyLarge(
                    'No messages yet',
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  AppText.bodyMedium(
                    'Start the conversation!',
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            );
          }

          // Scroll to bottom after messages load
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return ListView.builder(
            controller: _scrollController,
            padding: AppSpacing.paddingXL,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.senderId == _currentUserId;

              return _MessageBubble(
                message: message,
                isMe: isMe,
              );
            },
          );
        }

        return const Center(
          child: Text('Failed to load messages'),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return AppContainer(
      padding: AppSpacing.paddingXL,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                // Simple debouncing for typing indicator
                _handleTyping(value.isNotEmpty);
              },
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          FloatingActionButton(
            onPressed: _handleSendMessage,
            backgroundColor: AppColors.primary,
            mini: true,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppText.bodyMedium(
                message.content,
                color: isMe ? Colors.white : AppColors.onSurface,
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.xs),
            AppText.labelSmall(
              _formatTime(message.timestamp),
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
