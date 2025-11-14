import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/group_chat_model.dart';
import '../../providers/poll_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class PollsScreen extends StatefulWidget {
  final GroupChatModel groupChat;

  const PollsScreen({
    Key? key,
    required this.groupChat,
  }) : super(key: key);

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  void _showCreatePollDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null || !authProvider.currentUser!.isTutor) {
      return;
    }

    final questionController = TextEditingController();
    List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    bool allowMultiple = false;
    bool isAnonymous = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'What do you want to ask?',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Options',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...List.generate(optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              hintText: 'Enter option',
                            ),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                optionControllers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (optionControllers.length < 6)
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        optionControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Allow Multiple Choices'),
                  value: allowMultiple,
                  onChanged: (value) {
                    setDialogState(() {
                      allowMultiple = value ?? false;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Anonymous Voting'),
                  value: isAnonymous,
                  onChanged: (value) {
                    setDialogState(() {
                      isAnonymous = value ?? false;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
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
                if (questionController.text.trim().isEmpty) return;

                final options = optionControllers
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                if (options.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please add at least 2 options'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                final pollProvider = Provider.of<PollProvider>(context, listen: false);
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);

                final pollId = await pollProvider.createPoll(
                  groupChatId: widget.groupChat.id,
                  question: questionController.text.trim(),
                  options: options,
                  createdBy: authProvider.currentUser!.id,
                  allowMultiple: allowMultiple,
                  isAnonymous: isAnonymous,
                );

                if (pollId != null) {
                  // Send poll as message
                  await chatProvider.sendMessage(
                    groupChatId: widget.groupChat.id,
                    senderId: authProvider.currentUser!.id,
                    senderName: authProvider.currentUser!.name,
                    senderProfileUrl: authProvider.currentUser!.profilePictureUrl,
                    content: pollId,
                    messageType: AppConstants.messageTypePoll,
                  );
                }

                if (!mounted) return;

                Navigator.pop(context);

                if (pollId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Poll created and sent to chat'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTutor = authProvider.currentUser?.isTutor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polls'),
        actions: [
          if (isTutor)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreatePollDialog,
              tooltip: 'Create Poll',
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.poll,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Polls are sent to chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTutor
                  ? 'Create a poll and it will appear in the chat'
                  : 'Polls will appear in chat when tutors create them',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isTutor)
              ElevatedButton.icon(
                onPressed: _showCreatePollDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Poll'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
