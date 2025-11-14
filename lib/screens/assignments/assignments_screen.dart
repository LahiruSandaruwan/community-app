import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/assignment_model.dart';
import '../../models/group_chat_model.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class AssignmentsScreen extends StatefulWidget {
  final GroupChatModel groupChat;

  const AssignmentsScreen({
    Key? key,
    required this.groupChat,
  }) : super(key: key);

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assignmentProvider =
          Provider.of<AssignmentProvider>(context, listen: false);
      assignmentProvider.loadAssignments(widget.groupChat.id);
    });
  }

  void _showCreateAssignmentDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null || !authProvider.currentUser!.isTutor) {
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController(text: '100');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Assignment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Assignment title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Assignment details',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Points',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(DateFormat.yMMMd().format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;

              final assignmentProvider =
                  Provider.of<AssignmentProvider>(context, listen: false);

              final success = await assignmentProvider.createAssignment(
                communityId: widget.groupChat.communityId,
                groupChatId: widget.groupChat.id,
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                createdBy: authProvider.currentUser!.id,
                creatorName: authProvider.currentUser!.name,
                dueDate: selectedDate,
                totalPoints: int.tryParse(pointsController.text) ?? 100,
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Assignment created successfully'),
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
        title: const Text('Assignments'),
        actions: [
          if (isTutor)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateAssignmentDialog,
              tooltip: 'Create Assignment',
            ),
        ],
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, assignmentProvider, child) {
          if (assignmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (assignmentProvider.assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No assignments yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTutor
                        ? 'Create an assignment to get started'
                        : 'Check back later for assignments',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignmentProvider.assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignmentProvider.assignments[index];
              final isOverdue = assignment.dueDate.isBefore(DateTime.now());
              final hasSubmitted =
                  assignment.submittedBy.contains(authProvider.currentUser?.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _showAssignmentDetails(assignment),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                assignment.title,
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
                                color: isOverdue
                                    ? AppTheme.errorColor.withOpacity(0.1)
                                    : AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${assignment.totalPoints} pts',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue
                                      ? AppTheme.errorColor
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          assignment.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: isOverdue
                                  ? AppTheme.errorColor
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat.yMMMd().format(assignment.dueDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isOverdue
                                    ? AppTheme.errorColor
                                    : AppTheme.textSecondary,
                                fontWeight:
                                    isOverdue ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (!isTutor)
                              Chip(
                                label: Text(
                                  hasSubmitted ? 'Submitted' : 'Pending',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: hasSubmitted
                                    ? AppTheme.successColor.withOpacity(0.2)
                                    : AppTheme.warningColor.withOpacity(0.2),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              )
                            else
                              Text(
                                '${assignment.submittedBy.length} submissions',
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAssignmentDetails(AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(assignment.description),
              const SizedBox(height: 16),
              Text(
                'Due: ${DateFormat.yMMMd().add_jm().format(assignment.dueDate)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Total Points: ${assignment.totalPoints}'),
              const SizedBox(height: 8),
              Text('Submissions: ${assignment.submittedBy.length}'),
            ],
          ),
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
}
