import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart.dart';
import '../config/supabase_config.dart';

class SupabaseCartService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy giỏ hàng của user
  static Future<Cart?> getUserCart(int userId) async {
    try {
      final response =
          await _client
              .from('carts')
              .select('''
            *,
            cart_details:cart_details(
              *,
              product_variant:ma_bien_the_san_pham(
                *,
                product:ma_san_pham(
                  *,
                  product_images:product_images(*)
                ),
                size:ma_size(*),
                color:ma_mau(*)
              )
            )
          ''')
              .eq('ma_nguoi_dung', userId)
              .maybeSingle();

      if (response != null) {
        return Cart.fromJson(response);
      } else {
        // Tạo giỏ hàng mới nếu chưa có
        return await _createCart(userId);
      }
    } catch (e) {
      throw Exception('Failed to get user cart: $e');
    }
  }

  // Tạo giỏ hàng mới
  static Future<Cart?> _createCart(int userId) async {
    try {
      final response =
          await _client.from('carts').insert({'ma_nguoi_dung': userId}).select(
            '''
            *,
            cart_details:cart_details(
              *,
              product_variant:ma_bien_the_san_pham(
                *,
                product:ma_san_pham(
                  *,
                  product_images:product_images(*)
                ),
                size:ma_size(*),
                color:ma_mau(*)
              )
            )
          ''',
          ).single();

      return Cart.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create cart: $e');
    }
  }

  // Thêm sản phẩm vào giỏ hàng
  static Future<bool> addToCart({
    required int userId,
    required int productId,
    required int sizeId,
    required int colorId,
    required int quantity,
    required double price,
  }) async {
    try {
      // Lấy hoặc tạo giỏ hàng
      final cart = await getUserCart(userId);
      if (cart == null) return false;

      // Tìm product variant
      final variantResponse =
          await _client
              .from('product_variants')
              .select('ma_bien_the, ton_kho')
              .eq('ma_san_pham', productId)
              .eq('ma_size', sizeId)
              .eq('ma_mau', colorId)
              .maybeSingle();

      if (variantResponse == null) {
        throw Exception('Product variant not found');
      }

      final variantId = variantResponse['ma_bien_the'] as int;
      final stock = variantResponse['ton_kho'] as int;

      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      final existingItemResponse =
          await _client
              .from('cart_details')
              .select('ma_chi_tiet_gio_hang, so_luong')
              .eq('ma_gio_hang', cart.maGioHang)
              .eq('ma_bien_the_san_pham', variantId)
              .maybeSingle();

      final currentQty =
          existingItemResponse != null
              ? (existingItemResponse['so_luong'] as int)
              : 0;
      final newQty = currentQty + quantity;

      // Không cho phép vượt quá tồn kho
      if (newQty > stock) {
        // Throw plain string so UI doesn't show 'Exception:'
        throw 'Sản phẩm trong giỏ đã đạt tối đa theo tồn kho ($stock).';
      }

      if (existingItemResponse != null) {
        // Cập nhật số lượng
        await _client
            .from('cart_details')
            .update({'so_luong': newQty, 'gia_tien_tai_thoi_diem_them': price})
            .eq(
              'ma_chi_tiet_gio_hang',
              existingItemResponse['ma_chi_tiet_gio_hang'],
            );
      } else {
        // Thêm mới vào giỏ hàng
        await _client.from('cart_details').insert({
          'ma_gio_hang': cart.maGioHang,
          'ma_bien_the_san_pham': variantId,
          'so_luong': quantity,
          'gia_tien_tai_thoi_diem_them': price,
        });
      }

      return true;
    } catch (e) {
      // Preserve original message (string or exception)
      rethrow;
    }
  }

  // Cập nhật số lượng sản phẩm trong giỏ hàng
  static Future<bool> updateQuantity({
    required int cartDetailId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        // Xóa item nếu số lượng <= 0
        return await removeFromCart(cartDetailId);
      }

      // Lấy biến thể và tồn kho hiện tại
      final detail =
          await _client
              .from('cart_details')
              .select('ma_bien_the_san_pham')
              .eq('ma_chi_tiet_gio_hang', cartDetailId)
              .single();
      final variantId = detail['ma_bien_the_san_pham'] as int;

      final variant =
          await _client
              .from('product_variants')
              .select('ton_kho')
              .eq('ma_bien_the', variantId)
              .single();
      final stock = variant['ton_kho'] as int;

      if (quantity > stock) {
        throw 'Số lượng vượt quá tồn kho hiện có ($stock).';
      }

      await _client
          .from('cart_details')
          .update({'so_luong': quantity})
          .eq('ma_chi_tiet_gio_hang', cartDetailId);

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Xóa sửa phẩm khỏi giỏ hàng
  static Future<bool> removeFromCart(int cartDetailId) async {
    try {
      await _client
          .from('cart_details')
          .delete()
          .eq('ma_chi_tiet_gio_hang', cartDetailId);

      return true;
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  // Xóa toàn bộ giỏ hàng
  static Future<bool> clearCart(int userId) async {
    try {
      final cart = await getUserCart(userId);
      if (cart != null) {
        await _client
            .from('cart_details')
            .delete()
            .eq('ma_gio_hang', cart.maGioHang);
      }
      return true;
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Xóa các item đã chọn khỏi giỏ hàng
  static Future<bool> removeSelectedFromCart(
    int userId,
    Set<int> selectedCartDetailIds,
  ) async {
    try {
      if (selectedCartDetailIds.isEmpty) return true;
      final cart = await getUserCart(userId);
      if (cart == null) return true;
      await _client
          .from('cart_details')
          .delete()
          .or(
            selectedCartDetailIds
                .map((id) => 'ma_chi_tiet_gio_hang.eq.$id')
                .join(','),
          );
      return true;
    } catch (e) {
      throw Exception('Failed to remove selected items: $e');
    }
  }

  // Lấy số lượng sản phẩm trong giỏ hàng
  static Future<int> getCartItemCount(int userId) async {
    try {
      final cart = await getUserCart(userId);
      if (cart == null) return 0;

      final response = await _client
          .from('cart_details')
          .select('so_luong')
          .eq('ma_gio_hang', cart.maGioHang);

      int totalCount = 0;
      for (final item in response) {
        totalCount += item['so_luong'] as int;
      }

      return totalCount;
    } catch (e) {
      return 0;
    }
  }
}
