import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite.dart';
import '../models/product.dart';
import '../config/supabase_config.dart';

class SupabaseFavoriteService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy danh sách sản phẩm yêu thích
  static Future<List<Product>> getFavoriteProducts(int userId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('''
            ma_san_pham,
            products:ma_san_pham(
              *,
              product_images:product_images(*)
            )
          ''')
          .eq('ma_nguoi_dung', userId);

      return (response as List)
          .map((json) => Product.fromJson(json['products']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get favorite products: $e');
    }
  }

  // Thêm sản phẩm vào yêu thích
  static Future<bool> addToFavorites(int userId, int productId) async {
    try {
      await _client.from('favorites').insert({
        'ma_nguoi_dung': userId,
        'ma_san_pham': productId,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Xóa sản phẩm khỏi yêu thích
  static Future<bool> removeFromFavorites(int userId, int productId) async {
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('ma_nguoi_dung', userId)
          .eq('ma_san_pham', productId);

      return true;
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Kiểm tra sản phẩm có trong yêu thích không
  static Future<bool> isFavorite(int userId, int productId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('ma_san_pham')
          .eq('ma_nguoi_dung', userId)
          .eq('ma_san_pham', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check favorite status: $e');
    }
  }

  // Lấy số lượng sản phẩm yêu thích
  static Future<int> getFavoriteCount(String userId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('ma_san_pham')
          .eq('ma_nguoi_dung', userId);

      return response.length;
    } catch (e) {
      throw Exception('Failed to get favorite count: $e');
    }
  }
}