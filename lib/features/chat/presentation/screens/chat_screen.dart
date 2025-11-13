import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _initializeChat();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
    _currentUserName = user?.displayName ?? 'You';
  }

  void _initializeChat() {
    context.read<ChatBloc>().add(LoadMessages(widget.chatId));
    context.read<ChatBloc>().add(LoadChat(widget.chatId));
    _updateLastSeen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _updateLastSeen();
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
      context.read<ChatBloc>().add(
            UpdateLastSeen(chatId: widget.chatId, userId: _currentUserId!),
          );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage(String content) {
    if (_currentUserId == null) return;

    final state = context.read<ChatBloc>().state;
    String? replyToMessageId;

    if (state is MessagesLoaded && state.replyToMessage != null) {
      replyToMessageId = state.replyToMessage!.id;
    }

    final message = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'You',
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      replyToMessageId: replyToMessageId,
    );

    context.read<ChatBloc>().add(SendMessage(message));
    _scrollToBottom();
  }

  void _handleSendMedia(String filePath, MessageType type) {
    if (_currentUserId == null) return;

    final state = context.read<ChatBloc>().state;
    String? replyToMessageId;

    if (state is MessagesLoaded && state.replyToMessage != null) {
      replyToMessageId = state.replyToMessage!.id;
    }

    context.read<ChatBloc>().add(
          SendMediaMessage(
            filePath: filePath,
            chatId: widget.chatId,
            senderId: _currentUserId!,
            senderName: _currentUserName ?? 'You',
            type: type,
            replyToMessageId: replyToMessageId,
          ),
        );
    _scrollToBottom();
  }

  void _handleTyping(bool isTyping) {
    if (_currentUserId != null) {
      context.read<ChatBloc>().add(
            SetTypingStatus(
              chatId: widget.chatId,
              userId: _currentUserId!,
              isTyping: isTyping,
            ),
          );
    }
  }

  void _handleMessageTap(Message message) {
    if (message.type == MessageType.image || message.type == MessageType.video) {
      // TODO: Open media viewer
    } else if (message.type == MessageType.document) {
      // TODO: Download document
    }
  }

  void _handleMessageLongPress(Message message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(SetReplyToMessage(message));
              },
            ),
            if (message.senderId == _currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ChatBloc>().add(DeleteMessage(message.id));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _markMessagesAsRead(List<Message> messages) {
    if (_currentUserId == null) return;

    for (final message in messages) {
      if (message.senderId != _currentUserId &&
          message.status != MessageStatus.read) {
        context.read<ChatBloc>().add(
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
    if (state.chat == null) return '';

    final isTyping = state.chat!.isTyping[widget.otherUserId] ?? false;
    if (isTyping) return 'typing...';

    final lastSeen = state.chat!.lastSeen[widget.otherUserId];
    if (lastSeen == null) return 'offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) return 'online';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(
                      widget.otherUserName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is MessagesLoaded) {
                        final status = _getOnlineStatus(state);
                        return Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: status == 'online' || status == 'typing...'
                                ? Colors.green
                                : Colors.grey.shade600,
                            fontStyle: status == 'typing...'
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is MessageSent) {
            _scrollToBottom();
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
            final showTypingIndicator =
                state.chat?.isTyping[widget.otherUserId] ?? false;

            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount:
                              messages.length + (showTypingIndicator ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (showTypingIndicator && index == 0) {
                              return const Align(
                                alignment: Alignment.centerLeft,
                                child: TypingIndicator(),
                              );
                            }

                            final messageIndex =
                                showTypingIndicator ? index - 1 : index;
                            final message = messages[messageIndex];
                            final isMe = message.senderId == _currentUserId;

                            return MessageBubble(
                              message: message,
                              isMe: isMe,
                              onTap: () => _handleMessageTap(message),
                              onLongPress: () => _handleMessageLongPress(message),
                            );
                          },
                        ),
                ),
                MessageInput(
                  onSend: _handleSendMessage,
                  onSendMedia: _handleSendMedia,
                  onTyping: _handleTyping,
                  replyToMessage: state.replyToMessage,
                  onCancelReply: () {
                    context.read<ChatBloc>().add(const SetReplyToMessage(null));
                  },
                  isUploading: state.isUploading,
                  uploadProgress: state.uploadProgress,
                ),
              ],
            );
          }

          return const Center(child: Text('Failed to load messages'));
        },
      ),
    );
  }
}
