import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Firestore removed - using PocketBase now
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/community_service.dart';
import '../../services/pocketbase_auth_service.dart';
import '../../utils/theme.dart';

class MemberManagementScreen extends StatefulWidget {
  final CommunityModel community;

  const MemberManagementScreen({
    Key? key,
    required this.community,
  }) : super(key: key);

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final PocketBaseAuthService _authService = PocketBaseAuthService();
  List<UserModel> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<UserModel> members = [];
      for (String memberId in widget.community.memberIds) {
        final user = await _authService.getUserData(memberId);
        if (user != null) {
          members.add(user);
        }
      }

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(UserModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.name} from this community?',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final communityProvider =
        Provider.of<CommunityProvider>(context, listen: false);

    bool success = await communityProvider.removeMember(
      communityId: widget.community.id,
      userId: member.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} removed from community'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _loadMembers(); // Reload members
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            communityProvider.errorMessage ?? 'Failed to remove member',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _makeAdmin(UserModel member) async {
    // Check if member is already an admin
    if (widget.community.adminIds.contains(member.id)) {
      // Remove admin privileges
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Admin Privileges'),
          content: Text('Remove admin privileges from ${member.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        final communityService = CommunityService();
        await communityService.removeAdmin(
          communityId: widget.community.id,
          userId: member.id,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} is no longer an admin'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadMembers();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } else {
      // Make admin
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Make Admin'),
          content: Text('Give admin privileges to ${member.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Make Admin'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        final communityService = CommunityService();
        await communityService.makeAdmin(
          communityId: widget.community.id,
          userId: member.id,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} is now an admin'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadMembers();
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
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser != null &&
        widget.community.adminIds.contains(authProvider.currentUser!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Stats header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primaryLight.withOpacity(0.2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.people,
                            label: 'Total Members',
                            value: _members.length.toString(),
                          ),
                          _StatItem(
                            icon: Icons.school,
                            label: 'Students',
                            value: _members
                                .where((m) => m.isStudent)
                                .length
                                .toString(),
                          ),
                          _StatItem(
                            icon: Icons.person,
                            label: 'Tutors',
                            value: _members
                                .where((m) => m.isTutor)
                                .length
                                .toString(),
                          ),
                        ],
                      ),
                    ),

                    // Members list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final isMemberAdmin =
                              widget.community.adminIds.contains(member.id);
                          final isCurrentUser =
                              authProvider.currentUser?.id == member.id;

                          return _MemberTile(
                            member: member,
                            isAdmin: isMemberAdmin,
                            isCurrentUser: isCurrentUser,
                            canManage: isAdmin && !isCurrentUser,
                            onRemove: () => _removeMember(member),
                            onMakeAdmin: () => _makeAdmin(member),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No members found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final UserModel member;
  final bool isAdmin;
  final bool isCurrentUser;
  final bool canManage;
  final VoidCallback onRemove;
  final VoidCallback onMakeAdmin;

  const _MemberTile({
    required this.member,
    required this.isAdmin,
    required this.isCurrentUser,
    required this.canManage,
    required this.onRemove,
    required this.onMakeAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: member.profilePictureUrl != null
                  ? NetworkImage(member.profilePictureUrl!)
                  : null,
              backgroundColor: AppTheme.primaryLight,
              child: member.profilePictureUrl == null
                  ? Text(
                      member.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(member.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: member.isTutor
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.isTutor ? 'Tutor' : 'Student',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: member.isTutor
                          ? AppTheme.primaryColor
                          : AppTheme.successColor,
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove();
                  } else if (value == 'make_admin') {
                    onMakeAdmin();
                  }
                },
                itemBuilder: (context) => [
                  if (!isAdmin)
                    const PopupMenuItem(
                      value: 'make_admin',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text('Make Admin'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
