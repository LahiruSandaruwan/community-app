import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/community_service.dart';
import '../../models/group_chat_model.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final CommunityService _communityService = CommunityService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not authenticated'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: StreamBuilder<List<GroupChatModel>>(
        stream: _communityService.getUserGroupChats(authProvider.currentUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final groupChats = snapshot.data ?? [];

          if (groupChats.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groupChats.length,
            itemBuilder: (context, index) {
              final groupChat = groupChats[index];
              return _ChatListTile(
                groupChat: groupChat,
                currentUserId: authProvider.currentUser!.id,
                onTap: () {
                  chatProvider.selectGroupChat(
                    groupChat,
                    authProvider.currentUser!.id,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(groupChat: groupChat),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 100,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Chats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join a community to start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final GroupChatModel groupChat;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatListTile({
    required this.groupChat,
    required this.currentUserId,
    required this.onTap,
  });

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat.yMd().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = groupChat.unreadCounts[currentUserId] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: groupChat.isAnnouncementOnly
              ? AppTheme.warningColor.withOpacity(0.2)
              : AppTheme.primaryLight,
          child: Icon(
            groupChat.isAnnouncementOnly ? Icons.campaign : Icons.chat_bubble,
            color: groupChat.isAnnouncementOnly
                ? AppTheme.warningColor
                : AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                groupChat.name,
                style: TextStyle(
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            if (groupChat.lastMessageAt != null)
              Text(
                _formatTime(groupChat.lastMessageAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                groupChat.lastMessage ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  color: unreadCount > 0
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
