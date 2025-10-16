import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/size.dart';
import '../models/color.dart';
import '../models/product_variant.dart';
import '../config/supabase_config.dart';

class SupabaseVariantService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy danh sách sizes
  static Future<List<Size>> getSizes() async {
    try {
      final response = await _client
          .from('sizes')
          .select()
          .order('ten_size', ascending: true);

      return response.map<Size>((data) => Size.fromJson(data)).toList();
    } catch (e) {
      print('Error getting sizes: $e');
      return [];
    }
  }

  // Lấy danh sách colors
  static Future<List<ColorModel>> getColors() async {
    try {
      final response = await _client
          .from('colors')
          .select()
          .order('ten_mau', ascending: true);

      return response.map<ColorModel>((data) => ColorModel.fromJson(data)).toList();
    } catch (e) {
      print('Error getting colors: $e');
      return [];
    }
  }
   //  Lấy danh sách màu có trong biến thể của 1 sản phẩm
  static Future<List<ColorModel>> getColorsForProduct(int productId) async {
    try {
      final response = await _client
          .from('product_variants')
          .select('colors(*)')
          .eq('ma_san_pham', productId);

      final colorList = response
          .where((item) => item['colors'] != null)
          .map<ColorModel>((item) => ColorModel.fromJson(item['colors']))
          .toList();

      // Loại bỏ màu trùng lặp
      final uniqueColors = {
        for (var color in colorList) color.maMau: color,
      }.values.toList();

      return uniqueColors;
    } catch (e) {
      print('Error getting colors for product: $e');
      return [];
    }
  }
 // 🔹 Lấy danh sách size có trong biến thể của 1 sản phẩm
  static Future<List<Size>> getSizesForProduct(int productId) async {
    try {
      final response = await _client
          .from('product_variants')
          .select('sizes(*)')
          .eq('ma_san_pham', productId);

      final sizeList = response
          .where((item) => item['sizes'] != null)
          .map<Size>((item) => Size.fromJson(item['sizes']))
          .toList();

      // Loại bỏ trùng lặp theo mã size
      final uniqueSizes = {
        for (var size in sizeList) size.maSize: size,
      }.values.toList();

      return uniqueSizes;
    } catch (e) {
      print('Error getting sizes for product: $e');
      return [];
    }
  }

  // Lấy product variants cho một sản phẩm
  static Future<List<ProductVariant>> getProductVariants(int productId) async {
    try {
      final response = await _client
          .from('product_variants')
          .select('*, sizes(*), colors(*)')
          .eq('ma_san_pham', productId);

      return response.map<ProductVariant>((data) => ProductVariant.fromJson(data)).toList();
    } catch (e) {
      print('Error getting product variants: $e');
      return [];
    }
  }
}
