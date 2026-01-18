import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../notifications/services/notification_service.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/utils/logger.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/entities/chat.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_cubit.dart';
import '../bloc/chat_message_data.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';
import '../../../../core/helpers/user_extensions.dart';

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
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _initializeChat();
    _requestNotificationPermissionsOnFirstLaunch();
    // Set current chat ID to suppress notifications while viewing this chat
    di.sl<NotificationService>().setCurrentChatId(widget.chatId);
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
    _currentUserName = user?.displayName ?? 'You';
  }

  void _initializeChat() {
    // Streams are handled by StreamBuilder in build method
    _updateLastSeen();
  }

  /// Request notification permissions on first app launch
  Future<void> _requestNotificationPermissionsOnFirstLaunch() async {
    if (_hasRequestedPermissions) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAskedForPermissions =
          prefs.getBool('hasAskedForNotificationPermissions') ?? false;

      if (!hasAskedForPermissions) {
        // Show explanation dialog before requesting permissions
        if (mounted) {
          await _showPermissionExplanationDialog();
        }

        // Request notification permissions
        final notificationService = di.sl<NotificationService>();
        await notificationService.requestPermissions();

        // Mark as asked
        await prefs.setBool('hasAskedForNotificationPermissions', true);
      }

      _hasRequestedPermissions = true;
    } catch (e) {
      // Silently fail - permissions are optional
      Logger.logError('Error requesting notification permissions: $e', tag: 'ChatScreen');
    }
  }

  /// Show explanation dialog before requesting permissions
  Future<void> _showPermissionExplanationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.info),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              AppText.titleMedium('Enable Notifications'),
            ],
          ),
          content: AppText.bodyLarge(
            'Stay connected with your conversations! Enable notifications to receive instant alerts when you receive new messages, even when the app is closed.',
          ),
          actions: <Widget>[
            AppButton.text(
              child: AppText.bodyMedium('Not Now'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            AppButton.primary(
              child: AppText.bodyMedium('Enable', color: AppColors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _updateLastSeen();
    // Clear current chat ID so notifications can be shown again
    di.sl<NotificationService>().setCurrentChatId(null);
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
      context.read<ChatCubit>().updateLastSeen(widget.chatId, _currentUserId!);
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

    final state = context.read<ChatCubit>().state;
    String? replyToMessageId;

    if (state.hasData && state.data?.replyToMessage != null) {
      replyToMessageId = state.data!.replyToMessage!.id;
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

    context.read<ChatCubit>().sendMessage(message);
    _scrollToBottom();
  }

  void _handleSendMedia(String filePath, MessageType type) {
    if (_currentUserId == null) return;

    final state = context.read<ChatCubit>().state;
    String? replyToMessageId;

    if (state.hasData && state.data?.replyToMessage != null) {
      replyToMessageId = state.data!.replyToMessage!.id;
    }

    context.read<ChatCubit>().sendMediaMessage(
      filePath: filePath,
      chatId: widget.chatId,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'You',
      type: type,
      replyToMessageId: replyToMessageId,
    );
    _scrollToBottom();
  }

  void _handleTyping(bool isTyping) {
    if (_currentUserId != null) {
      context.read<ChatCubit>().setTypingStatus(
        widget.chatId,
        _currentUserId!,
        isTyping,
      );
    }
  }

  void _handleMessageTap(Message message) {
    if (message.type == MessageType.image && message.mediaUrl != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: AppColors.black,
            appBar: AppBar(
              backgroundColor: AppColors.black,
              iconTheme: const IconThemeData(color: AppColors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: AppColors.white),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (message.type == MessageType.document &&
        message.mediaUrl != null) {
      _launchURL(message.mediaUrl!);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        context.showSnackbar(
          message: 'Could not open document',
        );
      }
    }
  }

  void _handleMessageLongPress(Message message) {
    final chatCubit = context.read<ChatCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: AppText.bodyLarge('Reply'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                chatCubit.setReplyToMessage(message);
              },
            ),
            if (message.senderId == _currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: AppText.bodyLarge('Delete', color: AppColors.error),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  chatCubit.deleteMessage(message.id);
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
        context.read<ChatCubit>().markMessageAsRead(
          widget.chatId,
          message.id,
          _currentUserId!,
        );
      }
    }
  }

  String _getOnlineStatusFromChat(Chat? chat) {
    if (chat == null) return '';

    final isTyping = chat.isTyping[widget.otherUserId] ?? false;
    if (isTyping) return 'typing...';

    final lastSeen = chat.lastSeen[widget.otherUserId];
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
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? AppText.bodyMedium(
                      widget.otherUserName[0].toUpperCase(),
                      color: AppColors.white,
                    )
                  : null,
            ),
            AppSpacing.horizontalSpacing(SpacingSize.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(widget.otherUserName),
                  StreamBuilder<Either<Failure, Chat>>(
                    stream: context.read<ChatCubit>().watchChat(widget.chatId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.fold(
                          (failure) => const SizedBox.shrink(),
                          (chat) {
                            final status = _getOnlineStatusFromChat(chat);
                            return AppText.bodySmall(
                              status,
                              color: status == 'online' || status == 'typing...'
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            );
                          },
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
      body: BlocConsumer<ChatCubit, BaseState<ChatMessageData>>(
        listener: (context, state) {
          if (state is AsyncErrorState<ChatMessageData>) {
            context.showSnackbar(message: state.errorMessage);
          }
        },
        builder: (context, state) {
          final chatData = state.data ?? const ChatMessageData();
          final replyToMessage = chatData.replyToMessage;
          final isUploading = chatData.isUploading;
          final uploadProgress = chatData.uploadProgress;

          return Column(
            children: [
              Expanded(
                child: _MessagesList(
                  chatId: widget.chatId,
                  otherUserId: widget.otherUserId,
                  currentUserId: _currentUserId,
                  pendingMessages: chatData.pendingMessages,
                  scrollController: _scrollController,
                  onMessageTap: _handleMessageTap,
                  onMessageLongPress: _handleMessageLongPress,
                  onMarkAsRead: _markMessagesAsRead,
                ),
              ),
              MessageInput(
                onSend: _handleSendMessage,
                onSendMedia: _handleSendMedia,
                onTyping: _handleTyping,
                replyToMessage: replyToMessage,
                onCancelReply: () {
                  context.read<ChatCubit>().setReplyToMessage(null);
                },
                isUploading: isUploading,
                uploadProgress: uploadProgress,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Separate widget for messages list to handle stream independently
class _MessagesList extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String? currentUserId;
  final List<Message> pendingMessages;
  final ScrollController scrollController;
  final void Function(Message) onMessageTap;
  final void Function(Message) onMessageLongPress;
  final void Function(List<Message>) onMarkAsRead;

  const _MessagesList({
    required this.chatId,
    required this.otherUserId,
    required this.currentUserId,
    required this.pendingMessages,
    required this.scrollController,
    required this.onMessageTap,
    required this.onMessageLongPress,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Either<Failure, List<Message>>>(
      stream: context.read<ChatCubit>().watchMessages(chatId),
      builder: (context, messagesSnapshot) {
        // Get stream messages (or empty list if loading/error)
        List<Message> streamMessages = [];
        bool isLoading = messagesSnapshot.connectionState == ConnectionState.waiting;
        String? errorMessage;

        if (messagesSnapshot.hasData) {
          messagesSnapshot.data!.fold(
            (failure) => errorMessage = failure.failureMessage,
            (messages) {
              streamMessages = messages;
              // Mark messages as read
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onMarkAsRead(messages);
              });
            },
          );
        }

        // Merge stream messages with pending messages for instant display
        final allMessages = _mergeMessages(streamMessages, pendingMessages);

        return StreamBuilder<Either<Failure, Chat>>(
          stream: context.read<ChatCubit>().watchChat(chatId),
          builder: (context, chatSnapshot) {
            Chat? chat;
            if (chatSnapshot.hasData) {
              chatSnapshot.data!.fold(
                (failure) => null,
                (c) => chat = c,
              );
            }

            final showTypingIndicator = chat?.isTyping[otherUserId] ?? false;

            // Show loading only if no messages at all (pending or stream)
            if (isLoading && allMessages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (errorMessage != null && allMessages.isEmpty) {
              return Center(
                child: AppText.bodyMedium(errorMessage!),
              );
            }

            if (allMessages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppColors.disabled,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    AppText.bodyLarge(
                      'No messages yet',
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      'Start the conversation!',
                      color: AppColors.textDisabled,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allMessages.length + (showTypingIndicator ? 1 : 0),
              itemBuilder: (context, index) {
                if (showTypingIndicator && index == 0) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicator(),
                  );
                }

                final messageIndex = showTypingIndicator ? index - 1 : index;
                final message = allMessages[messageIndex];
                final isMe = message.senderId == currentUserId;

                return MessageBubble(
                  message: message,
                  isMe: isMe,
                  onTap: () => onMessageTap(message),
                  onLongPress: () => onMessageLongPress(message),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Merge stream messages with pending messages, removing duplicates
  List<Message> _mergeMessages(List<Message> streamMessages, List<Message> pending) {
    if (pending.isEmpty) return streamMessages;

    // Filter out pending messages that are now confirmed in stream
    final confirmedIds = streamMessages.map((m) => m.id).toSet();
    final stillPending = pending.where((p) =>
      !confirmedIds.contains(p.id) &&
      !streamMessages.any((m) => _isSameMessage(m, p))
    ).toList();

    // Merge and sort by timestamp (descending for reverse list)
    final merged = [...stillPending, ...streamMessages];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  /// Check if two messages are the same (for matching temp IDs with real IDs)
  bool _isSameMessage(Message a, Message b) {
    return a.senderId == b.senderId &&
        a.content == b.content &&
        a.type == b.type &&
        (a.timestamp.difference(b.timestamp).inSeconds.abs() < 5);
  }
}
