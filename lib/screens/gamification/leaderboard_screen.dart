import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamificationProvider =
          Provider.of<GamificationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      gamificationProvider.loadLeaderboard();
      if (authProvider.currentUser != null) {
        gamificationProvider.loadUserStats(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, gamificationProvider, child) {
          return Column(
            children: [
              // Current User Stats Card
              if (gamificationProvider.userStats != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Stats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.stars,
                            label: 'Level',
                            value: gamificationProvider.userStats!.level.toString(),
                          ),
                          _StatItem(
                            icon: Icons.emoji_events,
                            label: 'Points',
                            value: gamificationProvider.userStats!.totalPoints.toString(),
                          ),
                          _StatItem(
                            icon: Icons.local_fire_department,
                            label: 'Streak',
                            value: '${gamificationProvider.userStats!.currentStreak} days',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress to Level ${gamificationProvider.userStats!.level + 1}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: gamificationProvider.userStats!.progressToNextLevel,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Leaderboard Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Top Students',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Leaderboard List
              Expanded(
                child: gamificationProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : gamificationProvider.leaderboard.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.leaderboard,
                                  size: 80,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No data yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start participating to see rankings',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: gamificationProvider.leaderboard.length,
                            itemBuilder: (context, index) {
                              final userStats = gamificationProvider.leaderboard[index];
                              final isCurrentUser =
                                  userStats.userId == authProvider.currentUser?.id;
                              final rank = index + 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : null,
                                  border: isCurrentUser
                                      ? Border.all(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: rank <= 3
                                        ? (rank == 1
                                            ? Colors.amber
                                            : rank == 2
                                                ? Colors.grey[400]
                                                : Colors.brown[300])
                                        : AppTheme.primaryLight,
                                    child: rank <= 3
                                        ? Icon(
                                            Icons.emoji_events,
                                            color: Colors.white,
                                          )
                                        : Text(
                                            '$rank',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    'User ${userStats.userId.substring(0, 8)}',
                                    style: TextStyle(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Level ${userStats.level} • ${userStats.currentStreak} day streak',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${userStats.totalPoints} pts',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
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
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
