import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
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
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../services/typing_service.dart';

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
  final TypingService _typingService = TypingService();
  String? _currentUserId;
  String? _currentUserName;
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _initializeChat();
    _setupTypingService();
    _setupViewingStatus();
    _requestNotificationPermissionsOnFirstLaunch();
  }

  /// Set viewing status in RTDB for notification suppression
  void _setupViewingStatus() {
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      _typingService.setViewingChat(widget.chatId, userId);
    }
  }

  void _loadCurrentUser() {
    _currentUserId = context.currentUserId;
    final user = context.user;
    _currentUserName = user.displayName.isNotEmpty ? user.displayName : 'You';
  }

  void _initializeChat() {
    _updateLastSeen();
  }

  void _setupTypingService() {
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      _typingService.setupOnDisconnect(widget.chatId, userId);
    }
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
      Logger.logError(
        'Error requesting notification permissions: $e',
        tag: 'ChatScreen',
      );
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
    // Clear typing status when leaving chat
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      _typingService.clearTypingStatus(widget.chatId, userId);
      // Clear viewing status in RTDB so notifications can be shown again
      _typingService.clearViewingChat(userId);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateLastSeen();
      // Clear viewing status when app goes to background
      _typingService.clearViewingChat(userId);
    } else if (state == AppLifecycleState.resumed) {
      _updateLastSeen();
      // Restore viewing status when app comes back to foreground
      _typingService.setViewingChat(widget.chatId, userId);
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
    Message? replyToMessage;

    if (state.hasData && state.data?.replyToMessage != null) {
      replyToMessageId = state.data!.replyToMessage!.id;
      replyToMessage = state.data!.replyToMessage;
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
      replyToMessage: replyToMessage,
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
    // Use Realtime Database for faster typing updates
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      _typingService.setTypingStatus(widget.chatId, userId, isTyping);
    }
  }

  void _handleMessageTap(Message message) {
    if (message.type == MessageType.image && message.mediaUrl != null) {
      sl<NavigationService>().navigateTo(
        Routes.imageViewer,
        arguments: {'imageUrl': message.mediaUrl},
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
        context.showSnackbar(message: 'Could not open document');
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
        padding: AppSpacing.paddingXL,
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
                  chatCubit.deleteMessage(message.id, chatId: widget.chatId);
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

    // Typing is now handled by RTDB StreamBuilder, not here
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
        shape: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
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
                  StreamBuilder<bool>(
                    stream: _typingService.watchUserTyping(
                      widget.chatId,
                      widget.otherUserId,
                      _currentUserId ?? '',
                    ),
                    builder: (context, typingSnapshot) {
                      final isTyping = typingSnapshot.data ?? false;

                      if (isTyping) {
                        return AppText.bodySmall(
                          'typing...',
                          color: AppColors.success,
                        );
                      }

                      return StreamBuilder<Either<Failure, Chat>>(
                        stream: context.read<ChatCubit>().watchChat(
                          widget.chatId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return snapshot.data!.fold(
                              (failure) => const SizedBox.shrink(),
                              (chat) {
                                final status = _getOnlineStatusFromChat(chat);
                                return AppText.bodySmall(
                                  status,
                                  color: status == 'online'
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocManager<ChatCubit, BaseState<ChatMessageData>>(
        bloc: context.read<ChatCubit>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: true,
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
                  messages: chatData.messages,
                  scrollController: _scrollController,
                  onMessageTap: _handleMessageTap,
                  onMessageLongPress: _handleMessageLongPress,
                  onReply: (message) =>
                      context.read<ChatCubit>().setReplyToMessage(message),
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
        child: const SizedBox.shrink(),
      ),
    );
  }
}

/// Separate widget for messages list to handle stream independently
class _MessagesList extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String? currentUserId;
  final List<Message> messages;
  final ScrollController scrollController;
  final void Function(Message) onMessageTap;
  final void Function(Message) onMessageLongPress;
  final void Function(Message) onReply;
  final void Function(List<Message>) onMarkAsRead;
  final TypingService _typingService = TypingService();

  _MessagesList({
    required this.chatId,
    required this.otherUserId,
    required this.currentUserId,
    required this.messages,
    required this.scrollController,
    required this.onMessageTap,
    required this.onMessageLongPress,
    required this.onReply,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    // Stream updates the cubit's messages list
    return StreamBuilder<Either<Failure, List<Message>>>(
      stream: context.read<ChatCubit>().watchMessages(chatId),
      builder: (context, messagesSnapshot) {
        bool isLoading =
            messagesSnapshot.connectionState == ConnectionState.waiting;
        String? errorMessage;

        // When stream emits, update the cubit
        if (messagesSnapshot.hasData) {
          messagesSnapshot.data!.fold(
            (failure) => errorMessage = failure.failureMessage,
            (streamMessages) {
              // Update cubit with incoming messages (merges with local messages)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ChatCubit>().updateMessages(streamMessages);
                onMarkAsRead(streamMessages);
              });
            },
          );
        }

        // Sort messages for reverse ListView (newest first)
        final displayMessages = List<Message>.from(messages)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Use RTDB for faster typing indicator
        return StreamBuilder<bool>(
          stream: _typingService.watchUserTyping(chatId, otherUserId, currentUserId ?? ''),
          builder: (context, typingSnapshot) {
            final showTypingIndicator = typingSnapshot.data ?? false;

            // Show loading only if no messages at all
            if (isLoading && displayMessages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (errorMessage != null && displayMessages.isEmpty) {
              return Center(child: AppText.bodyMedium(errorMessage!));
            }

            if (displayMessages.isEmpty) {
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
              padding: AppSpacing.verticalPaddingSM,
              itemCount: displayMessages.length + (showTypingIndicator ? 1 : 0),
              itemBuilder: (context, index) {
                if (showTypingIndicator && index == 0) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicator(),
                  );
                }

                final messageIndex = showTypingIndicator ? index - 1 : index;
                final message = displayMessages[messageIndex];
                final isMe = message.senderId == currentUserId;
                final screenWidth = MediaQuery.of(context).size.width;

                return Dismissible(
                  key: Key('swipe_${message.id}'),
                  direction: isMe
                      ? DismissDirection.endToStart
                      : DismissDirection.startToEnd,
                  movementDuration: const Duration(milliseconds: 200),
                  dismissThresholds: const {
                    DismissDirection.endToStart: 0.2,
                    DismissDirection.startToEnd: 0.2,
                  },
                  confirmDismiss: (direction) async {
                    onReply(message);
                    return false;
                  },
                  background: Container(
                    constraints: BoxConstraints(maxWidth: screenWidth * 0.4),
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    padding: AppSpacing.horizontalPaddingXL,
                    child: Icon(Icons.reply, color: AppColors.info, size: 28),
                  ),
                  child: MessageBubble(
                    message: message,
                    isMe: isMe,
                    onTap: () => onMessageTap(message),
                    onLongPress: () => onMessageLongPress(message),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

}
