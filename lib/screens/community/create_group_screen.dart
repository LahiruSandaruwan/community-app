import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class CreateGroupScreen extends StatefulWidget {
  final String communityId;

  const CreateGroupScreen({
    Key? key,
    required this.communityId,
  }) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isAnnouncementOnly = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final communityProvider =
        Provider.of<CommunityProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final groupChat = await communityProvider.createGroupChat(
      communityId: widget.communityId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: authProvider.currentUser!.id,
      isAnnouncementOnly: _isAnnouncementOnly,
    );

    if (!mounted) return;

    if (groupChat != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successGroupCreated),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              communityProvider.errorMessage ?? 'Failed to create group'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group Chat'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group Name
                TextFormField(
                  controller: _nameController,
                  maxLength: AppConstants.maxGroupNameLength,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g., Homework Help',
                    prefixIcon: Icon(Icons.chat_bubble),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this group for?',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Announcement Only Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.campaign,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Announcement Only',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isAnnouncementOnly,
                            onChanged: (value) {
                              setState(() {
                                _isAnnouncementOnly = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When enabled, only tutors/admins can send messages in this group',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Create Button
                Consumer<CommunityProvider>(
                  builder: (context, communityProvider, child) {
                    return ElevatedButton(
                      onPressed: communityProvider.isLoading
                          ? null
                          : _handleCreateGroup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: communityProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Group'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
