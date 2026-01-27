import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/message.dart';
import '../../../services/typing_service.dart';
import '../../bloc/chat_cubit.dart';
import '../message_bubble.dart';
import '../typing_indicator.dart';
import 'messages_empty_state.dart';

class MessagesList extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? currentUserId;
  final List<Message> messages;
  final ScrollController scrollController;
  final void Function(Message) onMessageTap;
  final void Function(Message) onMessageLongPress;
  final void Function(Message) onReply;
  final void Function(List<Message>) onMarkAsRead;

  const MessagesList({
    super.key,
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
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  final TypingService _typingService = TypingService();
  late Stream<Either<Failure, List<Message>>> _messagesStream;
  late Stream<bool> _typingStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = context.read<ChatCubit>().watchMessages(widget.chatId);
    _typingStream = _typingService.watchUserTyping(
      widget.chatId,
      widget.otherUserId,
      widget.currentUserId ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Either<Failure, List<Message>>>(
      stream: _messagesStream,
      builder: (context, messagesSnapshot) {
        bool isLoading =
            messagesSnapshot.connectionState == ConnectionState.waiting;
        String? errorMessage;

        if (messagesSnapshot.hasData) {
          messagesSnapshot.data!.fold(
            (failure) => errorMessage = failure.failureMessage,
            (streamMessages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<ChatCubit>().updateMessages(streamMessages);
                  widget.onMarkAsRead(streamMessages);
                }
              });
            },
          );
        }

        final displayMessages = List<Message>.from(widget.messages)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return StreamBuilder<bool>(
          stream: _typingStream,
          builder: (context, typingSnapshot) {
            final showTypingIndicator = typingSnapshot.data ?? false;

            if (isLoading && displayMessages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (errorMessage != null && displayMessages.isEmpty) {
              return Center(child: AppText.bodyMedium(errorMessage!));
            }

            if (displayMessages.isEmpty) {
              return const MessagesEmptyState();
            }

            return ListView.builder(
              controller: widget.scrollController,
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
                final isMe = message.senderId == widget.currentUserId;
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
                    widget.onReply(message);
                    return false;
                  },
                  background: Container(
                    constraints: BoxConstraints(maxWidth: screenWidth * 0.4),
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    padding: AppSpacing.horizontalPaddingXL,
                    child: Icon(Icons.reply, color: AppColors.info, size: 28),
                  ),
                  child: MessageBubble(
                    message: message,
                    isMe: isMe,
                    onTap: () => widget.onMessageTap(message),
                    onLongPress: () => widget.onMessageLongPress(message),
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
