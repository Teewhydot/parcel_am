import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../domain/entities/chat.dart';

/// A tile widget displaying a single chat conversation in the list.
class ChatListTile extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  String get _otherParticipantId {
    return chat.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String get _participantName {
    return chat.participantNames[_otherParticipantId] ?? 'Unknown';
  }

  String? get _participantAvatar {
    return chat.participantAvatars[_otherParticipantId];
  }

  int get _unreadCount {
    return chat.unreadCount[currentUserId] ?? 0;
  }

  bool get _isTyping {
    return chat.isTyping[_otherParticipantId] ?? false;
  }

  String get _lastMessagePreview {
    if (_isTyping) return 'typing...';
    if (chat.lastMessage == null) return 'No messages yet';

    final message = chat.lastMessage!;
    if (message.isDeleted) return 'Message deleted';

    switch (message.type.name) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'document':
        return '📄 ${message.fileName ?? 'Document'}';
      default:
        return message.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: hasUnread
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.outline.withValues(alpha: 0.3),
          width: hasUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadius.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildAvatar(),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(hasUnread),
                      AppSpacing.verticalSpacing(SpacingSize.xs),
                      _buildMessagePreview(hasUnread),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _participantAvatar == null
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _participantAvatar != null
              ? ClipOval(
                  child: Image.network(
                    _participantAvatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                  ),
                )
              : _buildAvatarPlaceholder(),
        ),
        if (_isTyping)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: const Center(
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: _TypingDots(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: AppText.titleLarge(
        _participantName.isNotEmpty ? _participantName[0].toUpperCase() : '?',
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHeader(bool hasUnread) {
    return Row(
      children: [
        Expanded(
          child: AppText.titleMedium(
            _participantName,
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (chat.lastMessageTime != null) ...[
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          AppText.bodySmall(
            _formatTime(chat.lastMessageTime!),
            color: hasUnread ? AppColors.primary : AppColors.textSecondary,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ],
      ],
    );
  }

  Widget _buildMessagePreview(bool hasUnread) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            _lastMessagePreview,
            variant: TextVariant.bodyMedium,
            color: _isTyping
                ? AppColors.primary
                : hasUnread
                    ? AppColors.onSurface
                    : AppColors.textSecondary,
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            fontStyle: _isTyping ? FontStyle.italic : FontStyle.normal,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_unreadCount > 0) ...[
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: AppRadius.lg,
            ),
            child: AppText.bodySmall(
              _unreadCount > 99 ? '99+' : '$_unreadCount',
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 24 && now.day == time.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return timeago.format(time, locale: 'en_short');
    } else {
      return '${time.day}/${time.month}/${time.year.toString().substring(2)}';
    }
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = (_controller.value + delay) % 1.0;
            final opacity = animValue < 0.5 ? animValue * 2 : (1 - animValue) * 2;
            return Container(
              width: 2,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: opacity.clamp(0.3, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
