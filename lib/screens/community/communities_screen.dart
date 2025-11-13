import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../models/community_model.dart';
import '../../utils/theme.dart';
import 'create_community_screen.dart';
import 'join_community_screen.dart';
import 'community_detail_screen.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final communityProvider = Provider.of<CommunityProvider>(context);
    final isTutor = authProvider.currentUser?.isTutor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const JoinCommunityScreen(),
                ),
              );
            },
            tooltip: 'Join Community',
          ),
        ],
      ),
      body: communityProvider.communities.isEmpty
          ? _buildEmptyState(context, isTutor)
          : _buildCommunityList(context, communityProvider.communities),
      floatingActionButton: isTutor
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateCommunityScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTutor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 100,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Communities Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTutor
                  ? 'Create your first community to start connecting with students'
                  : 'Join a community using an invite code to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => isTutor
                        ? const CreateCommunityScreen()
                        : const JoinCommunityScreen(),
                  ),
                );
              },
              icon: Icon(isTutor ? Icons.add : Icons.group_add),
              label: Text(isTutor ? 'Create Community' : 'Join Community'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityList(
      BuildContext context, List<CommunityModel> communities) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return _CommunityCard(community: community);
      },
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final CommunityModel community;

  const _CommunityCard({required this.community});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.primaryLight,
          backgroundImage: community.communityImageUrl != null
              ? NetworkImage(community.communityImageUrl!)
              : null,
          child: community.communityImageUrl == null
              ? const Icon(Icons.groups, color: AppTheme.primaryColor, size: 30)
              : null,
        ),
        title: Text(
          community.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              community.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${community.memberCount} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${community.groupCount} groups',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CommunityDetailScreen(community: community),
            ),
          );
        },
      ),
    );
  }
}
