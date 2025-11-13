import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Upload to Firebase Storage
      String imageUrl = await _storageService.uploadProfilePicture(
        userId: authProvider.currentUser!.id,
        imageFile: File(image.path),
      );

      // Update user profile
      await authProvider.updateProfile(profilePictureUrl: imageUrl);

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nameController = TextEditingController(
      text: authProvider.currentUser?.name ?? '',
    );
    final phoneController = TextEditingController(
      text: authProvider.currentUser?.phoneNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.updateProfile(
                name: nameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
              );
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppConstants.successProfileUpdated),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Not authenticated'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Profile Picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryLight,
                      backgroundImage: user.profilePictureUrl != null
                          ? NetworkImage(user.profilePictureUrl!)
                          : null,
                      child: user.profilePictureUrl == null
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                          padding: EdgeInsets.zero,
                          onPressed: _isUploading ? null : _pickAndUploadImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User Name
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // User Email
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // User Role Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.isTutor
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.isTutor ? 'Tutor' : 'Student',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: user.isTutor
                          ? AppTheme.primaryColor
                          : AppTheme.successColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Options
                _ProfileOption(
                  icon: Icons.person,
                  title: 'Full Name',
                  subtitle: user.name,
                ),
                _ProfileOption(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: user.email,
                ),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  _ProfileOption(
                    icon: Icons.phone,
                    title: 'Phone Number',
                    subtitle: user.phoneNumber!,
                  ),
                _ProfileOption(
                  icon: Icons.badge,
                  title: 'Role',
                  subtitle: user.isTutor ? 'Tutor' : 'Student',
                ),
                _ProfileOption(
                  icon: Icons.groups,
                  title: 'Communities',
                  subtitle: '${user.communityIds.length} joined',
                ),

                const SizedBox(height: 24),
                const Divider(),

                // Settings Options
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'EduConnect',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      children: [
                        const Text(
                          'A community chat platform for tutors and students.',
                        ),
                      ],
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.logout, color: AppTheme.errorColor),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: _handleSignOut,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryLight,
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
