import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final Function(String, MessageType) onSendMedia;
  final Function(bool) onTyping;
  final Message? replyToMessage;
  final VoidCallback? onCancelReply;
  final bool isUploading;
  final double uploadProgress;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.onSendMedia,
    required this.onTyping,
    this.replyToMessage,
    this.onCancelReply,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  Timer? _typingStopDebounce;

  @override
  void dispose() {
    _controller.dispose();
    _typingStopDebounce?.cancel();
    super.dispose();
  }

  void _handleTextChanged(String text) {
    final isTyping = text.trim().isNotEmpty;
    
    // Cancel any pending "stop typing" timer
    _typingStopDebounce?.cancel();
    
    if (isTyping && !_isTyping) {
      // Started typing - send immediately for fast response
      _isTyping = true;
      widget.onTyping(true);
    } else if (!isTyping && _isTyping) {
      // Stopped typing - debounce to avoid flickering when pausing briefly
      _typingStopDebounce = Timer(const Duration(milliseconds: 1500), () {
        _isTyping = false;
        widget.onTyping(false);
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      _isTyping = false;
      widget.onTyping(false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onSendMedia(image.path, MessageType.image);
      }
    } catch (e) {
      context.showSnackbar(
        message: 'Failed to pick image: $e',
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        widget.onSendMedia(video.path, MessageType.video);
      }
    } catch (e) {
      context.showSnackbar(
        message: 'Failed to pick video: $e',
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.xl.topLeft),
      ),
      builder: (context) => Container(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: SpacingSize.xl.value),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.xs,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: AppColors.reversed,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo();
                  },
                ),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText(
            label,
            variant: TextVariant.bodySmall,
            fontSize: AppFontSize.bodySmall,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isUploading)
          LinearProgressIndicator(
            value: widget.uploadProgress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
          ),
        if (widget.replyToMessage != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingSize.lg.value,
              vertical: SpacingSize.sm.value,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: AppColors.outline),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 40,
                  color: AppColors.info,
                  margin: EdgeInsets.only(right: SpacingSize.md.value),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Replying to ${widget.replyToMessage!.senderName}',
                        variant: TextVariant.bodySmall,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                      SizedBox(height: SpacingSize.xs.value / 2),
                      AppText(
                        widget.replyToMessage!.type == MessageType.text
                            ? widget.replyToMessage!.content
                            : _getMediaTypeLabel(widget.replyToMessage!.type),
                        variant: TextVariant.bodySmall,
                        fontSize: AppFontSize.md,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onCancelReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        Container(
          padding: AppSpacing.paddingSM,
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.outline,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.info),
                  onPressed: widget.isUploading ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: Container(
                    padding: AppSpacing.horizontalPaddingLG,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.xxl,
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: _handleTextChanged,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: SpacingSize.md.value),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !widget.isUploading,
                    ),
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.sm),
                GestureDetector(
                  onTap: widget.isUploading ? null : _handleSend,
                  child: Container(
                    padding: EdgeInsets.all(SpacingSize.md.value),
                    decoration: BoxDecoration(
                      color: _controller.text.trim().isEmpty || widget.isUploading
                          ? AppColors.surfaceVariant
                          : AppColors.info,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: _controller.text.trim().isEmpty || widget.isUploading
                          ? AppColors.textSecondary
                          : AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
}
