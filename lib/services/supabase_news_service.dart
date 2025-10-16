import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/news.dart';

class SupabaseNewsService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<List<News>> getNews() async {
    try {
      final response = await _client
          .from('news')
          .select()
          .eq('trang_thai_hien_thi', true)
          .order('ngay_dang', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => News.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to load news: $e');
    }
  }
}
