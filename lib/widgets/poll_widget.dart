import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/poll_model.dart';
import '../providers/poll_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class PollWidget extends StatefulWidget {
  final String pollId;

  const PollWidget({
    Key? key,
    required this.pollId,
  }) : super(key: key);

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pollProvider = Provider.of<PollProvider>(context, listen: false);
      pollProvider.loadPoll(widget.pollId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Consumer<PollProvider>(
      builder: (context, pollProvider, child) {
        final poll = pollProvider.currentPoll;

        if (poll == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final totalVotes = poll.getTotalVotes();
        final userId = authProvider.currentUser?.id;
        final hasVoted = userId != null &&
            poll.votes.values.any((voters) => voters.contains(userId));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.poll,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'POLL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (poll.isAnonymous)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Anonymous',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                poll.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...poll.options.map((option) {
                final votes = poll.getOptionVotes(option);
                final percentage = totalVotes > 0 ? (votes / totalVotes) * 100 : 0.0;
                final isSelected = userId != null &&
                    (poll.votes[option]?.contains(userId) ?? false);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: hasVoted
                        ? null
                        : () => _vote(option),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (hasVoted)
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor.withOpacity(0.2),
                              ),
                              minHeight: 48,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  )
                                else if (!hasVoted)
                                  const Icon(
                                    Icons.radio_button_unchecked,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                if (isSelected || !hasVoted)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (hasVoted) ...[
                                  Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$votes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              Text(
                '$totalVotes vote${totalVotes != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _vote(String option) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pollProvider = Provider.of<PollProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    final success = await pollProvider.vote(
      pollId: widget.pollId,
      userId: authProvider.currentUser!.id,
      option: option,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote recorded'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
