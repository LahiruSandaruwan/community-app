import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class JoinCommunityScreen extends StatefulWidget {
  const JoinCommunityScreen({Key? key}) : super(key: key);

  @override
  State<JoinCommunityScreen> createState() => _JoinCommunityScreenState();
}

class _JoinCommunityScreenState extends State<JoinCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinCommunity() async {
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

    bool success = await communityProvider.joinCommunity(
      inviteCode: _inviteCodeController.text.trim().toUpperCase(),
      userId: authProvider.currentUser!.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successJoinedCommunity),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(communityProvider.errorMessage ??
              AppConstants.errorInvalidInviteCode),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Community'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.group_add,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Join a Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the invite code shared by your tutor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Invite Code Field
                TextFormField(
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Invite Code',
                    hintText: 'XXXXXXXX',
                    prefixIcon: Icon(Icons.key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an invite code';
                    }
                    if (value.length != 8) {
                      return 'Invite code must be 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Join Button
                Consumer<CommunityProvider>(
                  builder: (context, communityProvider, child) {
                    return ElevatedButton(
                      onPressed: communityProvider.isLoading
                          ? null
                          : _handleJoinCommunity,
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
                          : const Text('Join Community'),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Help text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ask your tutor for the community invite code',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
