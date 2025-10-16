import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/chat.dart';
import '../../services/supabase_chat_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final int adminUserId; // id user admin trong bảng users
  const ChatScreen({super.key, required this.adminUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int? _chatId;
  List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initChat();

    // Listen to text changes để enable/disable nút gửi
    _controller.addListener(() {
      setState(() {});
    });
  }

  Future<void> _initChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) {
      setState(() => _loading = false);
      return;
    }
    final chatId = await SupabaseChatService.ensureChatWithAdmin(
      auth.user!.maNguoiDung,
      widget.adminUserId,
    );
    if (chatId != null) {
      final msgs = await SupabaseChatService.fetchMessages(chatId);

      setState(() {
        _chatId = chatId;
        _messages = msgs;
        _loading = false;
      });

      SupabaseChatService.subscribeMessages(chatId).listen((rows) {
        if (!mounted) return;
        setState(() {
          _messages = rows;
        });
      });
    } else {
      setState(() => _loading = false);
    }
  }

  // Removed local ephemeral welcome; now persisted in DB when chat is created

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để gửi tin nhắn.')),
        );
      }
      return;
    }

    if (_chatId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang khởi tạo cuộc trò chuyện, vui lòng thử lại.'),
          ),
        );
      }
      return;
    }

    // Clear text field trước khi gửi
    _controller.clear();

    // Unfocus để ẩn keyboard
    _focusNode.unfocus();

    try {
      await SupabaseChatService.sendMessage(
        chatId: _chatId!,
        senderId: auth.user!.maNguoiDung,
        content: text,
      );
    } catch (e) {
      // Nếu gửi thất bại, hiển thị lại text
      _controller.text = text;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể gửi tin nhắn: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat với Admin'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final mine = msg.maNguoiGui == auth.user?.maNguoiDung;
                        return Align(
                          alignment:
                              mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  mine
                                      ? AppColors.accentRed.withOpacity(0.9)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg.noiDung,
                              style: TextStyle(
                                color:
                                    mine ? Colors.white : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                              textInputAction: TextInputAction.send,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  _canSend(context)
                                      ? AppColors.accentRed
                                      : AppColors.accentRed.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _canSend(context) ? _send : null,
                              icon: Icon(
                                Icons.send,
                                color:
                                    _canSend(context)
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                              ),
                              iconSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _canSend(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasText = _controller.text.trim().isNotEmpty;
    final isLoggedIn = auth.user != null;
    final chatReady = _chatId != null && !_loading;
    return hasText && isLoggedIn && chatReady;
  }
}
