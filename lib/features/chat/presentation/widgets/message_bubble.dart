import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyToMessage != null)
                _buildReplyPreview(context),
              _buildMessageContent(context),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              _buildMessageInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final reply = message.replyToMessage!;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe ? AppColors.infoLight : AppColors.surfaceVariant,
        borderRadius: AppRadius.sm,
        border: Border(
          left: BorderSide(
            color: isMe ? AppColors.info : AppColors.onSurfaceVariant,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodySmall(
            reply.senderName,
            fontWeight: FontWeight.bold,
            color: isMe ? AppColors.info : AppColors.textSecondary,
          ),
          const SizedBox(height: 2),
          AppText.bodySmall(
            reply.type == MessageType.text
                ? reply.content
                : _getMediaTypeLabel(reply.type),
            color: AppColors.textSecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return _buildVideoMessage(context);
      case MessageType.document:
        return _buildDocumentMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.info : AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
        ),
        border: Border.all(
          color: isMe
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.outline.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppText.bodyLarge(
        message.isDeleted ? 'This message was deleted' : message.content,
        color: isMe ? AppColors.white : AppColors.black,
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(
              color: isMe
                  ? AppColors.info.withValues(alpha: 0.3)
                  : AppColors.outline.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.md,
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl ?? '',
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 250,
                height: 250,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 250,
                height: 250,
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.error),
              ),
            ),
          ),
        ),
        if (message.content.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.info : AppColors.surfaceVariant,
              borderRadius: AppRadius.md,
              border: Border.all(
                color: isMe
                    ? AppColors.info.withValues(alpha: 0.3)
                    : AppColors.outline.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppText.bodyMedium(
              message.content,
              color: isMe ? AppColors.white : AppColors.black,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(
          color: isMe
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.outline.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: AppRadius.md,
            child: message.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: message.thumbnailUrl!,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 250,
                      height: 250,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : Container(
                    width: 250,
                    height: 250,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.videocam, size: 64),
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.54),
              borderRadius: AppRadius.pill,
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.play_arrow,
              color: AppColors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.info : AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: isMe
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.outline.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.infoDark : AppColors.surface,
              borderRadius: AppRadius.sm,
              border: Border.all(
                color: isMe
                    ? AppColors.white.withValues(alpha: 0.2)
                    : AppColors.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.description,
              color: isMe ? AppColors.white : AppColors.textSecondary,
              size: 24,
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  message.fileName ?? 'Document',
                  fontWeight: FontWeight.w500,
                  color: isMe ? AppColors.white : AppColors.black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  AppText.bodySmall(
                    _formatFileSize(message.fileSize!),
                    color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                  ),
              ],
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          Icon(
            Icons.download,
            color: isMe ? AppColors.white : AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          DateFormat('HH:mm').format(message.timestamp),
          variant: TextVariant.bodySmall,
          fontSize: AppFontSize.sm,
          color: AppColors.textSecondary,
        ),
        if (isMe) ...[
          AppSpacing.horizontalSpacing(SpacingSize.xs),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = AppColors.textSecondary;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = AppColors.textSecondary;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = AppColors.textSecondary;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = AppColors.info;
        break;
      case MessageStatus.failed:
        icon = Icons.priority_high;
        color = AppColors.error;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  String _getMediaTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.document:
        return '📄 Document';
      default:
        return '';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
