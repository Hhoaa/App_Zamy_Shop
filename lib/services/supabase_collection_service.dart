import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/collection.dart';

class SupabaseCollectionService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<List<Collection>> getCollections() async {
    try {
      print('Fetching collections...');
      final response = await _client
          .from('collections')
          .select('*, collection_images(duong_dan_anh)')
          .eq('trang_thai', true)
          .order('created_at', ascending: false);

      print('Raw collections response: ${response.length} items');
      
      if (response.isEmpty) {
        print('No collections found');
        return [];
      }

      final collections = response.map((data) => Collection.fromJson(data)).toList();
      print('Successfully parsed ${collections.length} collections');
      return collections;
    } catch (e) {
      print('Error fetching collections: $e');
      throw Exception('Failed to load collections: $e');
    }
  }

  static Future<List<String>> getCollectionImages(String collectionId) async {
    try {
      final response = await _client
          .from('collection_images')
          .select('duong_dan_anh')
          .eq('ma_bo_suu_tap', collectionId)
          .order('created_at');

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => data['duong_dan_anh'] as String).toList();
    } catch (e) {
      print('Error fetching collection images: $e');
      throw Exception('Failed to load collection images: $e');
    }
  }
}
