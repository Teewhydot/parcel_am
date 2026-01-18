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
      body: BlocListener<ChatCubit, BaseState<ChatMessageData>>(
        listener: (context, state) {
          if (state is AsyncErrorState<ChatMessageData>) {
            context.showSnackbar(message: state.errorMessage);
          }
          // Scroll to bottom when state is loaded (after message sent)
        },
        child: StreamBuilder<Either<Failure, List<Message>>>(
          stream: context.read<ChatCubit>().watchMessages(widget.chatId),
          builder: (context, messagesSnapshot) {
            if (messagesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (messagesSnapshot.hasError) {
              return Center(
                child: AppText.bodyMedium('Error loading messages'),
              );
            }

            if (!messagesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return messagesSnapshot.data!.fold(
              (failure) => Center(
                child: AppText.bodyMedium(failure.failureMessage),
              ),
              (messages) {
                // Mark messages as read when loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead(messages);
                });

                return StreamBuilder<Either<Failure, Chat>>(
                  stream: context.read<ChatCubit>().watchChat(widget.chatId),
                  builder: (context, chatSnapshot) {
                    Chat? chat;
                    if (chatSnapshot.hasData) {
                      chatSnapshot.data!.fold(
                        (failure) => null,
                        (c) => chat = c,
                      );
                    }

                    final showTypingIndicator =
                        chat?.isTyping[widget.otherUserId] ?? false;

                    return BlocBuilder<ChatCubit, BaseState<ChatMessageData>>(
                      buildWhen: (previous, current) {
                        // Only rebuild for state changes related to input
                        return current.hasData;
                      },
                      builder: (context, state) {
                        final chatData = state.data ?? const ChatMessageData();
                        final replyToMessage = chatData.replyToMessage;
                        final isUploading = chatData.isUploading;
                        final uploadProgress = chatData.uploadProgress;

                        return Column(
                          children: [
                            Expanded(
                              child: messages.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 64,
                                            color: AppColors.disabled,
                                          ),
                                          AppSpacing.verticalSpacing(
                                              SpacingSize.lg),
                                          AppText.bodyLarge(
                                            'No messages yet',
                                            color: AppColors.textSecondary,
                                          ),
                                          AppSpacing.verticalSpacing(
                                              SpacingSize.sm),
                                          AppText.bodyMedium(
                                            'Start the conversation!',
                                            color: AppColors.textDisabled,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      reverse: true,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      itemCount: messages.length +
                                          (showTypingIndicator ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (showTypingIndicator && index == 0) {
                                          return const Align(
                                            alignment: Alignment.centerLeft,
                                            child: TypingIndicator(),
                                          );
                                        }

                                        final messageIndex = showTypingIndicator
                                            ? index - 1
                                            : index;
                                        final message = messages[messageIndex];
                                        final isMe =
                                            message.senderId == _currentUserId;

                                        return MessageBubble(
                                          message: message,
                                          isMe: isMe,
                                          onTap: () =>
                                              _handleMessageTap(message),
                                          onLongPress: () =>
                                              _handleMessageLongPress(message),
                                        );
                                      },
                                    ),
                            ),
                            MessageInput(
                              onSend: _handleSendMessage,
                              onSendMedia: _handleSendMedia,
                              onTyping: _handleTyping,
                              replyToMessage: replyToMessage,
                              onCancelReply: () {
                                context
                                    .read<ChatCubit>()
                                    .setReplyToMessage(null);
                              },
                              isUploading: isUploading,
                              uploadProgress: uploadProgress,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
