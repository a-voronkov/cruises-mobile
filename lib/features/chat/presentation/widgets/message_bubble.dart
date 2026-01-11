import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/message.dart';
import '../../../../core/theme/app_colors.dart';

/// Message bubble widget (ChatGPT-style)
class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isUser
        ? (isDark ? AppColors.userMessageDark : AppColors.userMessageLight)
        : (isDark ? AppColors.aiMessageDark : AppColors.aiMessageLight);

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: isUser
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            child: Icon(
              isUser ? Icons.person : Icons.smart_toy,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role label
                Text(
                  isUser ? 'You' : 'Assistant',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),

                // Message text with markdown support
                MarkdownBody(
                  data: message.content,
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyLarge,
                    code: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      backgroundColor: isDark
                          ? Colors.black26
                          : Colors.black12,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary.withOpacity(0.6),
                  ),
                ),

                // Attachments (if any)
                if (message.attachments != null &&
                    message.attachments!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.attachments!
                          .map(
                            (attachment) => _buildAttachment(
                              context,
                              attachment,
                            ),
                          )
                          .toList(),
                    ),
                  ),

                // Status indicator for user messages
                if (isUser && message.status == MessageStatus.sending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sending...',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, MessageAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.type == AttachmentType.image
                ? Icons.image
                : Icons.attach_file,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            attachment.path.split('/').last,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }
}

