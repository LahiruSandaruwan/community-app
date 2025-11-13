import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/group_chat_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';
import 'group_info_screen.dart';

class ChatScreen extends StatefulWidget {
  final GroupChatModel groupChat;

  const ChatScreen({
    Key? key,
    required this.groupChat,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _stopTyping();
    super.dispose();
  }

  void _markMessagesAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      chatProvider.markAllMessagesAsRead(
        groupChatId: widget.groupChat.id,
        userId: authProvider.currentUser!.id,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    // Check if user can send messages (for announcement groups)
    if (widget.groupChat.isAnnouncementOnly &&
        !authProvider.currentUser!.isTutor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only tutors can send messages in this group'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();
    _stopTyping();

    bool success = await chatProvider.sendMessage(
      groupChatId: widget.groupChat.id,
      senderId: authProvider.currentUser!.id,
      senderName: authProvider.currentUser!.name,
      senderProfileUrl: authProvider.currentUser!.profilePictureUrl,
      content: messageText,
      messageType: widget.groupChat.isAnnouncementOnly
          ? AppConstants.messageTypeAnnouncement
          : AppConstants.messageTypeText,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }

    // Scroll to bottom
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    // Check if user can send messages (for announcement groups)
    if (widget.groupChat.isAnnouncementOnly &&
        !authProvider.currentUser!.isTutor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only tutors can send messages in this group'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Upload image to Firebase Storage
      String imageUrl = await _storageService.uploadChatImage(
        groupChatId: widget.groupChat.id,
        imageFile: File(image.path),
      );

      // Send message with image URL
      bool success = await chatProvider.sendMessage(
        groupChatId: widget.groupChat.id,
        senderId: authProvider.currentUser!.id,
        senderName: authProvider.currentUser!.name,
        senderProfileUrl: authProvider.currentUser!.profilePictureUrl,
        content: imageUrl,
        messageType: AppConstants.messageTypeImage,
      );

      setState(() {
        _isUploading = false;
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send image'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }

      // Scroll to bottom
      _scrollToBottom();
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startTyping() {
    if (!_isTyping) {
      _isTyping = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        chatProvider.setTypingIndicator(
          groupChatId: widget.groupChat.id,
          userId: authProvider.currentUser!.id,
          isTyping: true,
        );
      }
    }
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        chatProvider.setTypingIndicator(
          groupChatId: widget.groupChat.id,
          userId: authProvider.currentUser!.id,
          isTyping: false,
        );
      }
    }
  }

  void _showMessageOptions(MessageModel message, bool isMyMessage) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isTutor = authProvider.currentUser?.isTutor ?? false;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTutor)
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: AppTheme.primaryColor,
                ),
                title: Text(message.isPinned ? 'Unpin Message' : 'Pin Message'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePinMessage(message);
                },
              ),
            if (isMyMessage)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Message Info'),
              onTap: () {
                Navigator.pop(context);
                _showMessageInfo(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePinMessage(MessageModel message) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    await chatProvider.togglePinMessage(
      groupChatId: widget.groupChat.id,
      messageId: message.id,
      pin: !message.isPinned,
    );
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This message will be deleted for everyone.'),
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

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.deleteMessage(
      groupChatId: widget.groupChat.id,
      messageId: message.id,
    );
  }

  void _showMessageInfo(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              label: 'Sent by',
              value: message.senderName,
            ),
            _InfoRow(
              label: 'Time',
              value: DateFormat.yMd().add_jm().format(message.timestamp),
            ),
            _InfoRow(
              label: 'Read by',
              value: '${message.readCount} people',
            ),
            if (message.isPinned)
              const _InfoRow(
                label: 'Status',
                value: 'Pinned',
              ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupChat.name),
            if (widget.groupChat.isAnnouncementOnly)
              const Text(
                'Announcement Channel',
                style: TextStyle(fontSize: 12),
              )
            else if (chatProvider.typingUsers.isNotEmpty)
              const Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GroupInfoScreen(
                    groupChat: widget.groupChat,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final isMyMessage =
                          message.senderId == authProvider.currentUser!.id;

                      return MessageBubble(
                        message: message,
                        isMyMessage: isMyMessage,
                        onLongPress: () => _showMessageOptions(message, isMyMessage),
                      );
                    },
                  ),
          ),

          // Typing Indicator
          if (chatProvider.typingUsers.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TypingIndicator(),
            ),

          // Message Input
          _buildMessageInput(authProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.groupChat.isAnnouncementOnly
                ? Icons.campaign
                : Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.groupChat.isAnnouncementOnly
                ? 'Waiting for announcements from tutors'
                : 'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AuthProvider authProvider) {
    final canSend = !widget.groupChat.isAnnouncementOnly ||
        authProvider.currentUser!.isTutor;

    if (!canSend) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.backgroundColor,
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Only tutors can send messages in this announcement channel',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attach button
          IconButton(
            icon: _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : const Icon(Icons.attach_file, color: AppTheme.primaryColor),
            onPressed: _isUploading ? null : _pickAndSendImage,
            tooltip: 'Send image',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLength: AppConstants.maxMessageLength,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                counterText: '',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _startTyping();
                } else {
                  _stopTyping();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
