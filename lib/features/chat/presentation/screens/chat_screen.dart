import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../notifications/services/notification_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import 'package:parcel_am/features/chat/presentation/bloc/chat_cubit.dart';
import '../bloc/chat_message_data.dart';
import '../widgets/message_input.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../services/typing_service.dart';
import '../widgets/chat/chat_app_bar_content.dart';
import '../widgets/chat/message_options_sheet.dart';
import '../widgets/chat/notification_permission_dialog.dart';
import '../widgets/chat/messages_list.dart';

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

  Future<void> _requestNotificationPermissionsOnFirstLaunch() async {
    if (_hasRequestedPermissions) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAskedForPermissions =
          prefs.getBool('hasAskedForNotificationPermissions') ?? false;

      if (!hasAskedForPermissions) {
        if (mounted) {
          await NotificationPermissionDialog.show(context);
        }

        final notificationService = di.sl<NotificationService>();
        await notificationService.requestPermissions();

        await prefs.setBool('hasAskedForNotificationPermissions', true);
      }

      _hasRequestedPermissions = true;
    } catch (e) {
      Logger.logError(
        'Error requesting notification permissions: $e',
        tag: 'ChatScreen',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _updateLastSeen();
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      _typingService.clearTypingStatus(widget.chatId, userId);
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
      _typingService.clearViewingChat(userId);
    } else if (state == AppLifecycleState.resumed) {
      _updateLastSeen();
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
    MessageOptionsSheet.show(
      context,
      message: message,
      currentUserId: _currentUserId,
      onReply: () => chatCubit.setReplyToMessage(message),
      onDelete: () => chatCubit.deleteMessage(message.id, chatId: widget.chatId),
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
        title: ChatAppBarContent(
          otherUserName: widget.otherUserName,
          otherUserAvatar: widget.otherUserAvatar,
          chatId: widget.chatId,
          otherUserId: widget.otherUserId,
          currentUserId: _currentUserId,
          typingService: _typingService,
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
                child: MessagesList(
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
