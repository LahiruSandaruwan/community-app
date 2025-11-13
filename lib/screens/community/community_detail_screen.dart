import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/community_model.dart';
import '../../models/group_chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/theme.dart';
import '../chat/chat_screen.dart';
import 'create_group_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;

  const CommunityDetailScreen({
    Key? key,
    required this.community,
  }) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadGroupChats();
  }

  void _loadGroupChats() {
    final communityProvider =
        Provider.of<CommunityProvider>(context, listen: false);
    communityProvider.loadCommunityGroupChats(widget.community.id);
  }

  bool _isAdmin(String? userId) {
    return userId != null && widget.community.adminIds.contains(userId);
  }

  void _showInviteCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR Code
            QrImageView(
              data: widget.community.inviteCode,
              version: QrVersions.auto,
              size: 200,
            ),
            const SizedBox(height: 16),
            // Invite Code Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.community.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.community.inviteCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite code copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this code with students to invite them',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openGroupChat(GroupChatModel groupChat) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      chatProvider.selectGroupChat(groupChat, authProvider.currentUser!.id);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(groupChat: groupChat),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final communityProvider = Provider.of<CommunityProvider>(context);
    final isAdmin = _isAdmin(authProvider.currentUser?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showInviteCodeDialog,
            tooltip: 'Show Invite Code',
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'regenerate_code') {
                  _regenerateInviteCode();
                } else if (value == 'manage_members') {
                  // TODO: Implement member management
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'regenerate_code',
                  child: Text('Regenerate Invite Code'),
                ),
                const PopupMenuItem(
                  value: 'manage_members',
                  child: Text('Manage Members'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Community Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage: widget.community.communityImageUrl != null
                      ? NetworkImage(widget.community.communityImageUrl!)
                      : null,
                  child: widget.community.communityImageUrl == null
                      ? const Icon(Icons.groups,
                          color: AppTheme.primaryColor, size: 40)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.community.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoChip(
                      icon: Icons.people,
                      label: '${widget.community.memberCount} members',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.chat_bubble_outline,
                      label: '${communityProvider.groupChats.length} groups',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Group Chats List
          Expanded(
            child: communityProvider.groupChats.isEmpty
                ? _buildEmptyGroupsState(isAdmin)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: communityProvider.groupChats.length,
                    itemBuilder: (context, index) {
                      final groupChat = communityProvider.groupChats[index];
                      return _GroupChatTile(
                        groupChat: groupChat,
                        onTap: () => _openGroupChat(groupChat),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateGroupScreen(
                      communityId: widget.community.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Group'),
            )
          : null,
    );
  }

  Widget _buildEmptyGroupsState(bool isAdmin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Group Chats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Create your first group chat to start discussions'
                  : 'No group chats available yet',
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

  Future<void> _regenerateInviteCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Invite Code?'),
        content: const Text(
          'This will invalidate the current invite code. Members already in the community will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final communityProvider =
        Provider.of<CommunityProvider>(context, listen: false);

    final newCode =
        await communityProvider.regenerateInviteCode(widget.community.id);

    if (!mounted) return;

    if (newCode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New invite code: $newCode'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to regenerate invite code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupChatTile extends StatelessWidget {
  final GroupChatModel groupChat;
  final VoidCallback onTap;

  const _GroupChatTile({
    required this.groupChat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: groupChat.isAnnouncementOnly
              ? AppTheme.warningColor.withOpacity(0.2)
              : AppTheme.primaryLight,
          child: Icon(
            groupChat.isAnnouncementOnly
                ? Icons.campaign
                : Icons.chat_bubble,
            color: groupChat.isAnnouncementOnly
                ? AppTheme.warningColor
                : AppTheme.primaryColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                groupChat.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (groupChat.isAnnouncementOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Announcement',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              groupChat.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (groupChat.lastMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                groupChat.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
