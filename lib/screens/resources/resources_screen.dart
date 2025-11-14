import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/group_chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/theme.dart';

class ResourcesScreen extends StatefulWidget {
  final GroupChatModel groupChat;

  const ResourcesScreen({
    Key? key,
    required this.groupChat,
  }) : super(key: key);

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Load resources from Firestore
    // For now, showing empty state
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _uploadFile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'jpg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
        });

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Upload to Firebase Storage
        // TODO: Implement actual upload to resources folder
        await Future.delayed(const Duration(seconds: 2)); // Simulating upload

        setState(() {
          _isUploading = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName uploaded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        _loadResources();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTutor = authProvider.currentUser?.isTutor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Library'),
        actions: [
          if (isTutor)
            IconButton(
              icon: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload_file),
              onPressed: _isUploading ? null : _uploadFile,
              tooltip: 'Upload File',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No resources yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTutor
                            ? 'Upload study materials and documents'
                            : 'Check back later for study materials',
                        style: TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      if (isTutor) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _uploadFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload File'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _resources.length,
                  itemBuilder: (context, index) {
                    final resource = _resources[index];
                    return _ResourceCard(resource: resource);
                  },
                ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Map<String, dynamic> resource;

  const _ResourceCard({required this.resource});

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      case 'jpg':
      case 'png':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = resource['name'] ?? 'Unknown';
    final extension = fileName.split('.').last;
    final uploadedBy = resource['uploadedBy'] ?? 'Unknown';
    final uploadedAt = resource['uploadedAt'] as DateTime?;
    final fileSize = resource['size'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFileColor(extension).withOpacity(0.1),
          child: Icon(
            _getFileIcon(extension),
            color: _getFileColor(extension),
          ),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Uploaded by $uploadedBy'),
            if (uploadedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                DateFormat.yMd().add_jm().format(uploadedAt),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download feature - Coming soon!'),
              ),
            );
          },
        ),
        onTap: () {
          // TODO: Open file viewer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File viewer - Coming soon!'),
            ),
          );
        },
      ),
    );
  }
}
