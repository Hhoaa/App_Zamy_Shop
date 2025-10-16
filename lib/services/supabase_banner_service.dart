import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner_model.dart';
import '../config/supabase_config.dart';

class SupabaseBannerService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy danh sách banners
  static Future<List<BannerModel>> getBanners() async {
    try {
      print('Fetching banners...');
      final response = await _client
          .from('banners')
          .select()
          .eq('trang_thai', true)
          .order('ngay_tao', ascending: true);

      print('Raw banners response: ${response.length} items');
      
      final banners = response.map<BannerModel>((data) => BannerModel.fromJson(data)).toList();
      print('Successfully parsed ${banners.length} banners');
      return banners;
    } catch (e) {
      print('Error getting banners: $e');
      return [];
    }
  }

  // Lấy banner theo ID - SỬA: ID giờ là INTEGER
  static Future<BannerModel?> getBannerById(int id) async {  // ĐỔI String -> int
    try {
      final response = await _client
          .from('banners')
          .select()
          .eq('ma_banner', id)
          .eq('trang_thai', true)
          .single();

      return BannerModel.fromJson(response);
    } catch (e) {
      print('Error getting banner by id: $e');
      return null;
    }
  }
}