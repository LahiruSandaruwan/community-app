import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({Key? key}) : super(key: key);

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCommunity() async {
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

    final community = await communityProvider.createCommunity(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: authProvider.currentUser!.id,
    );

    if (!mounted) return;

    if (community != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successCommunityCreated),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(communityProvider.errorMessage ??
              'Failed to create community'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community'),
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
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create a community to organize your students into groups',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Community Name
                TextFormField(
                  controller: _nameController,
                  maxLength: AppConstants.maxCommunityNameLength,
                  decoration: const InputDecoration(
                    labelText: 'Community Name',
                    hintText: 'e.g., Grade 11 Physics',
                    prefixIcon: Icon(Icons.groups),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a community name';
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
                  maxLines: 4,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this community about?',
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
                const SizedBox(height: 32),

                // Create Button
                Consumer<CommunityProvider>(
                  builder: (context, communityProvider, child) {
                    return ElevatedButton(
                      onPressed: communityProvider.isLoading
                          ? null
                          : _handleCreateCommunity,
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
                          : const Text('Create Community'),
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
