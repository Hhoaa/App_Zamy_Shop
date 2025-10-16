import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

class AISearchService {
  // Hardcoded base URL as requested
  static const String baseUrl = 'https://apichat-production-20fa.up.railway.app';

  static Future<Map<String, dynamic>> searchByText(String message) async {
    final uri = Uri.parse('$baseUrl/api/search_products');
    // DEBUG
    // ignore: avoid_print
    print('[AI-SEARCH] POST $uri (text)');
    // ignore: avoid_print
    print('[AI-SEARCH] payload: {"message": "${message.replaceAll('\n',' ')}"}');
    final res = await http.post(
      uri,
      headers: { 'Content-Type': 'application/json' },
      body: jsonEncode({ 'message': message }),
    );
    // DEBUG
    // ignore: avoid_print
    print('[AI-SEARCH] status: ${res.statusCode}');
    // ignore: avoid_print
    print('[AI-SEARCH] body: ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('AI search failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> searchByImage({required String message, required XFile image}) async {
    final uri = Uri.parse('$baseUrl/api/search_products');
    // DEBUG
    // ignore: avoid_print
    print('[AI-SEARCH] POST $uri (image)');
    // ignore: avoid_print
    print('[AI-SEARCH] message: ${message.replaceAll('\n',' ')}');
    // ignore: avoid_print
    print('[AI-SEARCH] file: name=${image.name}, path=${image.path}');
    final req = http.MultipartRequest('POST', uri)
      ..fields['message'] = message;
    final bytes = await image.readAsBytes();
    req.files.add(http.MultipartFile.fromBytes(
      'file', bytes,
      filename: image.name,
      contentType: _lookupContentType(image.path),
    ));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    // DEBUG
    // ignore: avoid_print
    print('[AI-SEARCH] status: ${res.statusCode}');
    // ignore: avoid_print
    print('[AI-SEARCH] body: ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('AI image search failed: ${res.statusCode} ${res.body}');
  }

  static http_parser.MediaType? _lookupContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return http_parser.MediaType('image', 'jpeg');
    if (lower.endsWith('.png')) return http_parser.MediaType('image', 'png');
    if (lower.endsWith('.webp')) return http_parser.MediaType('image', 'webp');
    return null;
  }
}

