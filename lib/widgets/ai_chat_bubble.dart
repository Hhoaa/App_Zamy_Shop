import 'package:flutter/material.dart';

import '../screens/ai_chat/ai_chat_screen.dart';
import '../navigation/navigator_key.dart';
import '../theme/app_colors.dart';

class FloatingAIChatButton extends StatelessWidget {
  const FloatingAIChatButton({super.key});

  void _openAIChat(BuildContext context) {
    final navigator = AppNavigator.navigator;
    if (navigator != null) {
      navigator.push(
        MaterialPageRoute(builder: (context) => const AIChatScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    // Fixed bottom-right bubble without Draggable to avoid Overlay requirement
    return Positioned(
      right: 16,
      bottom: (padding.bottom > 0 ? padding.bottom : 16) + 140, // Đẩy lên cao hơn để tránh che nút mua hàng
      child: GestureDetector(
        onTap: () => _openAIChat(context),
        child: _buildBubble(),
      ),
    );
  }

  Widget _buildBubble() {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      shape: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.accentRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}


