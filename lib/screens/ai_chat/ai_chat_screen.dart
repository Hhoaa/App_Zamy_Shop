import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/ai_chat_service.dart';
import '../../widgets/ai_chat/suggested_products_widget.dart';
import '../../widgets/common/collapsible_size_recommendation_widget.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ai_chat/bubble_visibility.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> _suggestedProducts = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isDisposed = false; // guard for async callbacks

  @override
  void initState() {
    super.initState();
    BubbleVisibility.hide(); // Ẩn AI chat bubble khi vào trang AI chat
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _isDisposed = true;
    BubbleVisibility.show(); // Hiện lại AI chat bubble khi rời trang AI chat
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    if (!mounted || _isDisposed) return;
    setState(() {
      _chatHistory.add({
        'type': 'ai',
        'message': 'Xin chào! Tôi là AI tư vấn thời trang của Zamy Shop. Tôi có thể giúp bạn:\n\n'
            '• Tìm sản phẩm phù hợp với chiều cao, cân nặng\n'
            '• Gợi ý màu sắc, phong cách\n'
            '• Tư vấn cho từng dịp đặc biệt\n'
            '• Phân tích hình ảnh để tìm sản phẩm tương tự\n\n'
            'Hãy chia sẻ với tôi về sở thích và nhu cầu của bạn nhé! 😊',
        'timestamp': DateTime.now(),
      });
    });
  }

  void _scrollToBottom() {
    if (!mounted || _isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      if (_scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (!mounted || _isDisposed) return;
    setState(() {
      _chatHistory.add({
        'type': 'user',
        'message': message,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
      _isLoading = true;
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final serializableChatHistory = _chatHistory
          .where((msg) => msg['type'] == 'user')
          .map((msg) => {
                'type': msg['type'],
                'message': msg['message'],
                'timestamp': (msg['timestamp'] as DateTime).toIso8601String(),
              })
          .toList();

      final response = await AIChatService.sendMessage(
        message: message,
        chatHistory: serializableChatHistory,
        userProfile: {
          'height': '165cm',
          'weight': '55kg',
          'favorite_colors': ['đen', 'trắng', 'xanh'],
        },
      );

      if (!mounted || _isDisposed) return;
      setState(() {
        _isLoading = false;
        _isTyping = false;
        
        if (response['success']) {
          _chatHistory.add({
            'type': 'ai',
            'message': response['ai_message'],
            'timestamp': DateTime.now(),
          });
          if (response['suggested_products'] != null) {
            _suggestedProducts = List<Map<String, dynamic>>.from(
              response['suggested_products']
            );
          }
        } else {
          _chatHistory.add({
            'type': 'ai',
            'message': 'Xin lỗi, tôi gặp sự cố kỹ thuật. Vui lòng thử lại sau.',
            'timestamp': DateTime.now(),
          });
        }
      });

      _scrollToBottom();
      if (_suggestedProducts.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || _isDisposed) return;
          _messageFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isLoading = false;
        _isTyping = false;
        _chatHistory.add({
          'type': 'ai',
          'message': 'Xin lỗi, tôi gặp sự cố kỹ thuật. Vui lòng thử lại sau.',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  Future<void> _sendImageMessage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      if (!mounted || _isDisposed) return;
      setState(() {
        _chatHistory.add({
          'type': 'user',
          'message': 'Tôi muốn tìm sản phẩm tương tự như hình này',
          'image': image.path,
          'timestamp': DateTime.now(),
        });
        _isLoading = true;
        _isTyping = true;
      });

      _scrollToBottom();

      final serializableChatHistory = _chatHistory
          .where((msg) => msg['type'] == 'user')
          .map((msg) => {
                'type': msg['type'],
                'message': msg['message'],
                'timestamp': (msg['timestamp'] as DateTime).toIso8601String(),
              })
          .toList();

      final response = await AIChatService.sendMessageWithImage(
        message: 'Tôi muốn tìm sản phẩm tương tự như hình này',
        imageFile: File(image.path),
        chatHistory: serializableChatHistory,
        userProfile: {
          'height': '165cm',
          'weight': '55kg',
          'favorite_colors': ['đen', 'trắng', 'xanh'],
        },
      );

      if (!mounted || _isDisposed) return;
      setState(() {
        _isLoading = false;
        _isTyping = false;
        
        if (response['success']) {
          _chatHistory.add({
            'type': 'ai',
            'message': response['ai_message'],
            'timestamp': DateTime.now(),
          });
          if (response['suggested_products'] != null) {
            _suggestedProducts = List<Map<String, dynamic>>.from(
              response['suggested_products']
            );
          }
        } else {
          _chatHistory.add({
            'type': 'ai',
            'message': 'Xin lỗi, tôi không thể phân tích hình ảnh này. Vui lòng thử lại.',
            'timestamp': DateTime.now(),
          });
        }
      });

      _scrollToBottom();
      if (_suggestedProducts.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || _isDisposed) return;
          _messageFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isLoading = false;
        _isTyping = false;
        _chatHistory.add({
          'type': 'ai',
          'message': 'Xin lỗi, tôi gặp sự cố khi xử lý hình ảnh.',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  void _onProductTap(Map<String, dynamic> product) {
    print('🔄 [DEBUG] Product tapped: ${product}');
    
    // Extract product id as int
    int? productId;
    final rawId = product['id'] ?? product['ma_san_pham'];
    if (rawId is int) {
      productId = rawId;
    } else if (rawId != null) {
      productId = int.tryParse(rawId.toString());
    }

    print('🔄 [DEBUG] Product ID: $productId');
    
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở sản phẩm này')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: productId!),
      ),
    );
  }

  void _onAddToCart(Map<String, dynamic> product) {
    // TODO: Implement add to cart functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${product['name']} vào giỏ hàng'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'AI Tư vấn thời trang',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Clear chat history
              setState(() {
                _chatHistory.clear();
                _suggestedProducts.clear();
              });
            },
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Làm mới cuộc trò chuyện',
          ),
        ],
      ),
      // Handle keyboard manually to avoid Column overflow
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Chat messages and suggested products
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Chat messages container
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Chat messages
                            ...List.generate(
                              _chatHistory.length + (_isTyping ? 1 : 0),
                              (index) {
                                if (index == _chatHistory.length && _isTyping) {
                                  return _buildTypingIndicator();
                                }
                                final message = _chatHistory[index];
                                return _buildMessageBubble(message);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Suggested products
                  if (_suggestedProducts.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SuggestedProductsWidget(
                        products: _suggestedProducts,
                        onProductTap: _onProductTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Input area - pinned bottom; add manual padding for keyboard
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderLight.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                ),
                // Ensure input area is always on top
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Size recommendation widget
                    CollapsibleSizeRecommendationWidget(
                      onSizeRecommended: (size) {
                        _messageController.text = 'Tôi muốn tìm sản phẩm size $size';
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Text input row
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          // Camera button
                          IconButton(
                            onPressed: _isLoading ? null : _sendImageMessage,
                            icon: const Icon(Icons.camera_alt),
                            color: AppColors.textSecondary,
                            iconSize: 22,
                          ),
                          
                          // Text input
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _messageFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                hintStyle: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                ),
                              ),
                              maxLines: null,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              onTap: () {
                                _messageFocusNode.requestFocus();
                              },
                            ),
                          ),
                          
                          // Send button
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              onPressed: _isLoading ? null : _sendMessage,
                              icon: Icon(
                                _isLoading ? Icons.hourglass_empty : Icons.send,
                                color: _isLoading ? AppColors.textLight : AppColors.accentRed,
                              ),
                              iconSize: 22,
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
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['type'] == 'user';
    final hasImage = message['image'] != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentRed,
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accentRed : AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(message['image']),
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message['timestamp']),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentRed,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentRed),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI đang suy nghĩ...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
