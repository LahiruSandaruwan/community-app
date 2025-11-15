import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../models/group_chat_model.dart';
import '../../models/resource_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/resource_service.dart';
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
  final ResourceService _resourceService = ResourceService();
  bool _isUploading = false;

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

        // Upload to Firebase Storage and Firestore
        await _resourceService.uploadResource(
          groupChatId: widget.groupChat.id,
          file: file,
          fileName: fileName,
          uploadedBy: authProvider.currentUser!.id,
          uploaderName: authProvider.currentUser!.name,
        );

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

  Future<void> _downloadFile(ResourceModel resource) async {
    try {
      final uri = Uri.parse(resource.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open file';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteResource(ResourceModel resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: Text('Are you sure you want to delete "${resource.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _resourceService.deleteResource(resource.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource deleted successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
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
      body: StreamBuilder<List<ResourceModel>>(
        stream: _resourceService.getResources(widget.groupChat.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final resources = snapshot.data ?? [];

          if (resources.isEmpty) {
            return Center(
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
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final resource = resources[index];
              return _ResourceCard(
                resource: resource,
                isTutor: isTutor,
                currentUserId: authProvider.currentUser?.id ?? '',
                onDownload: () => _downloadFile(resource),
                onDelete: () => _deleteResource(resource),
              );
            },
          );
        },
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final ResourceModel resource;
  final bool isTutor;
  final String currentUserId;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _ResourceCard({
    required this.resource,
    required this.isTutor,
    required this.currentUserId,
    required this.onDownload,
    required this.onDelete,
  });

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
    final canDelete = isTutor || resource.uploadedBy == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFileColor(resource.extension).withOpacity(0.1),
          child: Icon(
            _getFileIcon(resource.extension),
            color: _getFileColor(resource.extension),
          ),
        ),
        title: Text(
          resource.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Uploaded by ${resource.uploaderName}'),
            const SizedBox(height: 2),
            Text(
              '${DateFormat.yMd().add_jm().format(resource.uploadedAt)} • ${resource.formattedSize}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: onDownload,
              tooltip: 'Download',
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete),
                color: AppTheme.errorColor,
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
          ],
        ),
        onTap: onDownload,
      ),
    );
  }
}
