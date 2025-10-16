import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_search_service.dart';

class SizeRecommendationApi {
  static Future<Map<String, dynamic>> recommend({
    required String height,
    required String weight,
    String? bust,
    String? waist,
    String? hip,
    String? category,
    String? gender,
    bool useGemini = false,
  }) async {
    final uri = Uri.parse('${AISearchService.baseUrl}/api/recommend_size');
    final body = <String, dynamic>{
      'height': height,
      'weight': weight,
      'bust': bust,
      'waist': waist,
      'hip': hip,
      'category': category,
      'gender': gender,
      'use_gemini': useGemini,
    }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Size API failed: ${res.statusCode} ${res.body}');
  }
}


