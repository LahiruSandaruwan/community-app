import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../utils/theme.dart';
import 'voice_message_widget.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onAddReaction;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMyMessage,
    this.onLongPress,
    this.onReactionTap,
    this.onAddReaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMyMessage) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: message.senderProfileUrl != null
                    ? NetworkImage(message.senderProfileUrl!)
                    : null,
                backgroundColor: AppTheme.primaryLight,
                child: message.senderProfileUrl == null
                    ? Text(
                        message.senderName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMyMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name (only for others' messages)
                  if (!isMyMessage)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),

                  // Message bubble
                  Container(
                    decoration: BoxDecoration(
                      color: _getMessageColor(),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                        bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pinned indicator
                        if (message.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: isMyMessage
                                      ? Colors.black54
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isMyMessage
                                        ? Colors.black54
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Announcement indicator
                        if (message.isAnnouncement)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.campaign,
                                  size: 14,
                                  color: AppTheme.warningColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Announcement',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Message content
                        if (message.messageType == 'image')
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: message.content,
                              width: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 200,
                                color: AppTheme.backgroundColor,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 200,
                                height: 200,
                                color: AppTheme.backgroundColor,
                                child: const Center(
                                  child: Icon(Icons.error),
                                ),
                              ),
                            ),
                          )
                        else if (message.messageType == 'voice')
                          VoiceMessageWidget(
                            voiceUrl: message.content,
                            duration: Duration(
                              seconds: message.metadata?['duration'] ?? 0,
                            ),
                            isMyMessage: isMyMessage,
                          )
                        else
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isMyMessage ? Colors.black87 : Colors.black87,
                            ),
                          ),

                        const SizedBox(height: 4),

                        // Timestamp and read count
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.jm().format(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMyMessage
                                    ? Colors.black54
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            if (isMyMessage && message.readCount > 1) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all,
                                size: 16,
                                color: message.readCount > 1
                                    ? AppTheme.primaryColor
                                    : Colors.black54,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reactions display
                  if (message.reactions.isNotEmpty || onAddReaction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildReactions(),
                    ),
                ],
              ),
            ),
            if (isMyMessage) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // Existing reactions
        ...message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final userIds = entry.value;
          final count = userIds.length;

          return GestureDetector(
            onTap: () => onReactionTap?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),

        // Add reaction button
        if (onAddReaction != null)
          GestureDetector(
            onTap: onAddReaction,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Color _getMessageColor() {
    if (message.isAnnouncement) {
      return AppTheme.warningColor.withOpacity(0.2);
    }
    return isMyMessage ? AppTheme.myMessageColor : AppTheme.otherMessageColor;
  }
}
