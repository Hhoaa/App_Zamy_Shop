import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../models/chat.dart';
import '../../services/supabase_chat_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final int chatId;
  final int otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  Stream<List<ChatMessage>>? _messageStream;
  StreamSubscription<List<ChatMessage>>? _messageSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupChatListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await SupabaseChatService.fetchMessages(widget.chatId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupChatListeners() {
    _messageStream = SupabaseChatService.subscribeMessages(widget.chatId);
    _messageSub = _messageStream!.listen((msgs) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Hỗ trợ khách hàng',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textLight,
          ),
          SizedBox(height: 16),
          Text(
            'Bắt đầu trò chuyện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chúng tôi sẽ phản hồi trong thời gian sớm nhất',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageItem(_messages[index]);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    final isMe = currentUser != null && message.maNguoiGui == currentUser.maNguoiDung;
    final isImage = message.loaiTinNhan == 'image';
    final isFile = message.loaiTinNhan == 'file';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentRed,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.accentRed : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: isMe ? null : Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.noiDung,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: AppColors.lightGray,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.mediumGray,
                            ),
                          );
                        },
                      ),
                    )
                  else if (isFile)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'File đính kèm',
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      message.noiDung,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                _formatTime(message.thoiGianGui),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.textSecondary,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Attach file
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              // Take photo
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.accentRed),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                _sendMessage();
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.user;
      if (currentUser == null) return;

      _messageController.clear();
      // Gửi tin nhắn lên server
      await SupabaseChatService.sendUserMessageWithAutoAdminReply(
        chatId: widget.chatId,
        userId: currentUser.maNguoiDung,
        content: text,
      );
      // Hiển thị ngay tin nhắn của user + bubble "admin đang xử lý" tại UI (không lưu DB)
      setState(() {
        _messages.add(
          ChatMessage(
            maTinNhan: -2, // id giả cho UI (user message vừa gửi)
            maChat: widget.chatId,
            maNguoiGui: currentUser.maNguoiDung,
            noiDung: text,
            loaiTinNhan: 'local_user',
            thoiGianGui: DateTime.now(),
            daDoc: true,
            maTinNhanCha: null,
          ),
        );
        _messages.add(
          ChatMessage(
            maTinNhan: -1, // id giả cho UI
            maChat: widget.chatId,
            maNguoiGui: widget.otherUserId,
            noiDung: 'Cảm ơn bạn đã liên hệ! Nhân viên sẽ phản hồi trong giây lát...',
            loaiTinNhan: 'auto_admin_ui',
            thoiGianGui: DateTime.now(),
            daDoc: false,
            maTinNhanCha: null,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
