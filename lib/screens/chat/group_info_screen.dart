import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/group_chat_model.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/community_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../assignments/assignments_screen.dart';
import '../attendance/attendance_screen.dart';
import '../gamification/leaderboard_screen.dart';
import '../polls/polls_screen.dart';
import '../resources/resources_screen.dart';
import 'search_messages_screen.dart';

class GroupInfoScreen extends StatefulWidget {
  final GroupChatModel groupChat;

  const GroupInfoScreen({
    Key? key,
    required this.groupChat,
  }) : super(key: key);

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _members = [];
  List<MessageModel> _pinnedMessages = [];
  bool _isLoadingMembers = true;
  bool _isLoadingPinned = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadPinnedMessages();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      List<UserModel> members = [];
      for (String memberId in widget.groupChat.memberIds) {
        DocumentSnapshot doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(memberId)
            .get();

        if (doc.exists) {
          members.add(UserModel.fromFirestore(doc));
        }
      }

      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _loadPinnedMessages() async {
    setState(() {
      _isLoadingPinned = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      List<MessageModel> pinned =
          await chatProvider.searchMessages(
        groupChatId: widget.groupChat.id,
        query: '', // Get all messages
      );

      // Filter pinned messages
      pinned = pinned.where((msg) => msg.isPinned).toList();

      setState(() {
        _pinnedMessages = pinned;
        _isLoadingPinned = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPinned = false;
      });
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer receive messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) return;

      final communityService = CommunityService();
      await communityService.removeMemberFromCommunity(
        communityId: widget.groupChat.communityId,
        userId: userId,
      );

      if (!mounted) return;

      // Navigate back to communities screen
      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have left the community'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _toggleMute(bool mute) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) return;

      final authService = AuthService();

      if (mute) {
        await authService.muteGroupChat(userId, widget.groupChat.id);
      } else {
        await authService.unmuteGroupChat(userId, widget.groupChat.id);
      }

      // Reload user to update the state
      await authService.getUserData(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mute ? 'Group muted' : 'Group unmuted'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showMemberProfile(UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: member.profilePictureUrl != null
                    ? NetworkImage(member.profilePictureUrl!)
                    : null,
                backgroundColor: AppTheme.primaryLight,
                child: member.profilePictureUrl == null
                    ? Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Email', value: member.email),
            _InfoRow(
              label: 'Role',
              value: member.isTutor ? 'Tutor' : 'Student',
            ),
            if (member.phoneNumber != null && member.phoneNumber!.isNotEmpty)
              _InfoRow(label: 'Phone', value: member.phoneNumber!),
            _InfoRow(
              label: 'Status',
              value: member.isOnline ? 'Online' : 'Offline',
            ),
            if (!member.isOnline)
              _InfoRow(
                label: 'Last Seen',
                value: _formatLastSeen(member.lastSeen),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat.yMd().add_jm().format(lastSeen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTutor = authProvider.currentUser?.isTutor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.2),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: widget.groupChat.isAnnouncementOnly
                        ? AppTheme.warningColor.withOpacity(0.2)
                        : AppTheme.primaryLight,
                    child: Icon(
                      widget.groupChat.isAnnouncementOnly
                          ? Icons.campaign
                          : Icons.chat_bubble,
                      size: 50,
                      color: widget.groupChat.isAnnouncementOnly
                          ? AppTheme.warningColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.groupChat.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.groupChat.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (widget.groupChat.isAnnouncementOnly)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Announcement Only Channel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Features Section
            const SizedBox(height: 16),
            const _SectionHeader(
              title: 'Features',
              icon: Icons.extension,
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: AppTheme.primaryColor),
              title: const Text('Assignments'),
              subtitle: const Text('View and submit assignments'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AssignmentsScreen(
                      groupChat: widget.groupChat,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.how_to_reg, color: AppTheme.primaryColor),
              title: const Text('Attendance'),
              subtitle: const Text('Track and mark attendance'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AttendanceScreen(
                      groupChat: widget.groupChat,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.leaderboard, color: AppTheme.primaryColor),
              title: const Text('Leaderboard'),
              subtitle: const Text('View rankings and stats'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.poll, color: AppTheme.primaryColor),
              title: const Text('Polls'),
              subtitle: const Text('Create and vote on polls'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PollsScreen(
                      groupChat: widget.groupChat,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.folder, color: AppTheme.primaryColor),
              title: const Text('Resource Library'),
              subtitle: const Text('Study materials and documents'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ResourcesScreen(
                      groupChat: widget.groupChat,
                    ),
                  ),
                );
              },
            ),

            // Pinned Messages Section
            if (widget.groupChat.pinnedMessageIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Pinned Messages',
                icon: Icons.push_pin,
                count: widget.groupChat.pinnedMessageIds.length,
              ),
              _isLoadingPinned
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _pinnedMessages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No pinned messages',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : Column(
                          children: _pinnedMessages.map((msg) {
                            return _PinnedMessageTile(message: msg);
                          }).toList(),
                        ),
            ],

            // Members Section
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Members',
              icon: Icons.people,
              count: widget.groupChat.memberIds.length,
            ),
            _isLoadingMembers
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: _members.map((member) {
                      return _MemberTile(
                        member: member,
                        onTap: () => _showMemberProfile(member),
                      );
                    }).toList(),
                  ),

            // Group Settings
            const SizedBox(height: 16),
            const _SectionHeader(
              title: 'Settings',
              icon: Icons.settings,
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isMuted = authProvider.currentUser?.mutedGroupChatIds
                        .contains(widget.groupChat.id) ??
                    false;

                return ListTile(
                  leading: const Icon(Icons.notifications, color: AppTheme.primaryColor),
                  title: const Text('Notifications'),
                  subtitle: Text(isMuted ? 'Unmute this group' : 'Mute this group'),
                  trailing: Switch(
                    value: isMuted,
                    onChanged: (value) => _toggleMute(value),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.search, color: AppTheme.primaryColor),
              title: const Text('Search Messages'),
              subtitle: const Text('Find messages in this group'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchMessagesScreen(
                      groupChat: widget.groupChat,
                    ),
                  ),
                );
              },
            ),

            // Danger Zone
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: AppTheme.errorColor),
              title: const Text(
                'Leave Group',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onTap: _leaveGroup,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final UserModel member;
  final VoidCallback onTap;

  const _MemberTile({
    required this.member,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: member.profilePictureUrl != null
                ? NetworkImage(member.profilePictureUrl!)
                : null,
            backgroundColor: AppTheme.primaryLight,
            child: member.profilePictureUrl == null
                ? Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          if (member.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.onlineColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(member.name),
      subtitle: Text(
        member.isTutor ? 'Tutor' : 'Student',
        style: TextStyle(
          fontSize: 12,
          color: member.isTutor ? AppTheme.primaryColor : AppTheme.successColor,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _PinnedMessageTile extends StatelessWidget {
  final MessageModel message;

  const _PinnedMessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.push_pin, color: AppTheme.warningColor),
        title: Text(
          message.senderName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMd().add_jm().format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.content));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message copied to clipboard'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
