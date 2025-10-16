import 'package:flutter/material.dart';

class AppColors {
  // Màu chính từ hình ảnh
  static const Color primary = Color(0xFF8B4513); // Màu nâu đậm chính
  static const Color primaryBeige = Color(0xFFF8F5F0); // Màu be nhạt chính
  static const Color secondaryBeige = Color(0xFFEAE0D5); // Màu be đậm hơn
  static const Color darkBrown = Color(0xFF8B4513); // Màu nâu đậm cho text
  static const Color accentRed = Color(0xFFD9534F); // Màu đỏ accent
  static const Color priceRed = Color(0xFFDC3545); // Màu đỏ cho giá
  static const Color goldYellow = Color(0xFFFFD700); // Màu vàng cho sao
  static const Color lightGray = Color(0xFFF5F5F5); // Màu xám nhạt
  static const Color mediumGray = Color(0xFFCCCCCC); // Màu xám trung bình
  static const Color darkGray = Color(0xFF666666); // Màu xám đậm
  
  // Màu nền
  static const Color background = primaryBeige;
  static const Color cardBackground = Colors.white;
  static const Color inputBackground = Colors.white;
  
  // Màu text
  static const Color textPrimary = darkBrown;
  static const Color textSecondary = darkGray;
  static const Color textLight = mediumGray;
  
  // Màu button
  static const Color buttonPrimary = Colors.black;
  static const Color buttonSecondary = Colors.white;
  static const Color buttonAccent = accentRed;
  
  // Màu border
  static const Color border = mediumGray;
  static const Color borderLight = mediumGray;
  static const Color borderDark = darkGray;
  
  // Màu status
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);
}
