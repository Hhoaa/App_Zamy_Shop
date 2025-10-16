import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/store.dart';

class SupabaseStoreService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<List<Store>> getStores() async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .eq('trang_thai', true);

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => Store.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching stores: $e');
      throw Exception('Failed to load stores: $e');
    }
  }
}
