import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AIChatService {
  static const String baseUrl = 'https://apichat-production-20fa.up.railway.app';
  // Gửi tin nhắn text đến AI chatbot
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    List<Map<String, dynamic>>? chatHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      print('[AI Chat] Sending message: $message');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'chat_history': chatHistory ?? [],
          'user_profile': userProfile ?? {},
        }),
      );

      print('[AI Chat] Response status: ${response.statusCode}');
      print('[AI Chat] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'ai_message': data['ai_message'] ?? '',
          'suggested_products': data['suggested_products'] ?? [],
          'keywords': data['keywords'] ?? [],
          'notes': data['notes'] ?? '',
        };
      } else {
        return {
          'success': false,
          'error': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('[AI Chat] Error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // Gửi tin nhắn với hình ảnh đến AI chatbot
  static Future<Map<String, dynamic>> sendMessageWithImage({
    required String message,
    required File imageFile,
    List<Map<String, dynamic>>? chatHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      print('[AI Chat] Sending message with image: $message');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/chat_with_image'),
      );

      // Thêm tin nhắn text
      request.fields['message'] = message;
      
      // Thêm chat history
      if (chatHistory != null) {
        request.fields['chat_history'] = jsonEncode(chatHistory);
      }
      
      // Thêm user profile
      if (userProfile != null) {
        request.fields['user_profile'] = jsonEncode(userProfile);
      }

      // Thêm file hình ảnh
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[AI Chat] Image response status: ${response.statusCode}');
      print('[AI Chat] Image response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'ai_message': data['ai_message'] ?? '',
          'suggested_products': data['suggested_products'] ?? [],
          'keywords': data['keywords'] ?? [],
          'notes': data['notes'] ?? '',
        };
      } else {
        return {
          'success': false,
          'error': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('[AI Chat] Image error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // Lấy danh sách sản phẩm gợi ý dựa trên keywords
  static Future<List<Map<String, dynamic>>> getSuggestedProducts({
    required List<String> keywords,
  }) async {
    try {
      print('[AI Chat] Getting suggested products for: $keywords');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/search_products'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': keywords.join(' '),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['products'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('[AI Chat] Get products error: $e');
      return [];
    }
  }
}
