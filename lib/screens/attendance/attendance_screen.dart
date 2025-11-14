import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/group_chat_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class AttendanceScreen extends StatefulWidget {
  final GroupChatModel groupChat;

  const AttendanceScreen({
    Key? key,
    required this.groupChat,
  }) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      attendanceProvider.loadSessions(widget.groupChat.id);
    });
  }

  void _showCreateSessionDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null || !authProvider.currentUser!.isTutor) {
      return;
    }

    final sessionNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Attendance Session'),
        content: TextField(
          controller: sessionNameController,
          decoration: const InputDecoration(
            labelText: 'Session Name',
            hintText: 'e.g., Monday Class, Lab Session',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (sessionNameController.text.trim().isEmpty) return;

              final attendanceProvider =
                  Provider.of<AttendanceProvider>(context, listen: false);

              final sessionId = await attendanceProvider.createSession(
                groupChatId: widget.groupChat.id,
                sessionName: sessionNameController.text.trim(),
                createdBy: authProvider.currentUser!.id,
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (sessionId != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session created successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTutor = authProvider.currentUser?.isTutor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          if (isTutor)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateSessionDialog,
              tooltip: 'Create Session',
            ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (attendanceProvider.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.how_to_reg_outlined,
                    size: 80,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No attendance sessions yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTutor
                        ? 'Create a session to track attendance'
                        : 'Check back when tutor starts a session',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: attendanceProvider.sessions.length,
            itemBuilder: (context, index) {
              final session = attendanceProvider.sessions[index];
              final isActive = session.endTime == null;
              final hasMarked =
                  session.presentUserIds.contains(authProvider.currentUser?.id) ||
                      session.lateUserIds.contains(authProvider.currentUser?.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.sessionName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : AppTheme.textSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Ended',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppTheme.successColor
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Started: ${DateFormat.jm().format(session.startTime)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (session.endTime != null) ...[
                            const SizedBox(width: 16),
                            Text(
                              'Ended: ${DateFormat.jm().format(session.endTime!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _AttendanceCount(
                            icon: Icons.check_circle,
                            count: session.presentUserIds.length,
                            label: 'Present',
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 16),
                          _AttendanceCount(
                            icon: Icons.schedule,
                            count: session.lateUserIds.length,
                            label: 'Late',
                            color: AppTheme.warningColor,
                          ),
                        ],
                      ),
                      if (!isTutor && isActive && !hasMarked) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _markAttendance(session.id),
                            icon: const Icon(Icons.how_to_reg),
                            label: const Text('Mark Attendance'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                      if (!isTutor && hasMarked) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'You marked attendance',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isTutor && isActive) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _endSession(session.id),
                            icon: const Icon(Icons.stop),
                            label: const Text('End Session'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAttendance(String sessionId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    final success = await attendanceProvider.markAttendance(
      sessionId: sessionId,
      userId: authProvider.currentUser!.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance marked successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _endSession(String sessionId) async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('This will close the attendance session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await attendanceProvider.endSession(sessionId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session ended'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}

class _AttendanceCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _AttendanceCount({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
