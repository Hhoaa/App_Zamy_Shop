import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseDiscountService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy danh sách mã giảm giá có sẵn
  static Future<List<Map<String, dynamic>>> getAvailableDiscounts() async {
    try {
      print('[DEBUG] SupabaseDiscountService: Bắt đầu query discounts...');
      
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      print('[DEBUG] Thời gian hiện tại: $nowIso');
      
      final response = await _client
          .from('discounts')
          .select('*')
          .eq('trang_thai_kich_hoat', true)
          .gte('ngay_ket_thuc', nowIso)
          .lte('ngay_bat_dau', nowIso);

      print('[DEBUG] SupabaseDiscountService: Query thành công, có ${(response as List).length} kết quả');
      
      final result = (response as List).cast<Map<String, dynamic>>();
      
      // Debug từng mã giảm giá
      for (var discount in result) {
        print('   - Code: ${discount['code']}, Tên: ${discount['noi_dung']}, Kết thúc: ${discount['ngay_ket_thuc']}');
      }
      
      return result;
    } catch (e, stackTrace) {
      print('[DEBUG] SupabaseDiscountService: Lỗi query discounts: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      throw Exception('Failed to get available discounts: $e');
    }
  }

  // Lấy danh sách mã giảm giá khả dụng và chưa từng dùng bởi user
  static Future<List<Map<String, dynamic>>> getAvailableDiscountsForUser(int userId) async {
    // 1) Lấy các mã đang còn hiệu lực
    final discounts = await getAvailableDiscounts();

    try {
      // 2) Lấy ID trạng thái "Đã hủy" để loại các đơn đã hủy khỏi usage
      int? cancelledStatusId;
      try {
        final cancelled = await _client
            .from('order_statuses')
            .select('ma_trang_thai_don_hang')
            .eq('ten_trang_thai', 'Đã hủy')
            .maybeSingle();
        if (cancelled != null) {
          cancelledStatusId = cancelled['ma_trang_thai_don_hang'] as int?;
        }
      } catch (_) {}

      // 3) Lấy danh sách mã giảm giá mà user đã dùng (đơn không bị hủy)
      final usedRows = await _client
          .from('orders')
          .select('ma_giam_gia, ma_trang_thai_don_hang')
          .eq('ma_nguoi_dung', userId)
          .not('ma_giam_gia', 'is', null);

      final usedIds = <int>{};
      for (final row in (usedRows as List).cast<Map<String, dynamic>>()) {
        final id = row['ma_giam_gia'] as int?;
        final statusId = row['ma_trang_thai_don_hang'] as int?;
        if (id != null) {
          // Nếu biết được id trạng thái hủy, thì bỏ qua đơn đã hủy. Nếu không biết, cứ coi là đã dùng.
          if (cancelledStatusId != null) {
            if (statusId != cancelledStatusId) usedIds.add(id);
          } else {
            usedIds.add(id);
          }
        }
      }

      // 4) Lọc bỏ các mã user đã dùng
      final filtered = discounts.where((d) {
        final id = d['ma_giam_gia'] as int?;
        return id == null ? true : !usedIds.contains(id);
      }).toList();

      return filtered;
    } catch (e) {
      // Nếu có lỗi khi lọc theo user, fallback trả về danh sách chung
      return discounts;
    }
  }

  // Kiểm tra mã giảm giá có hợp lệ không
  static Future<Map<String, dynamic>?> validateDiscount({
    required String discountCode,
    required double orderAmount,
    required int userId,
  }) async {
    try {
      final response = await _client
          .from('discounts')
          .select('*')
          .eq('code', discountCode)
          .eq('trang_thai_kich_hoat', true)
          .gte('ngay_ket_thuc', DateTime.now().toIso8601String())
          .lte('ngay_bat_dau', DateTime.now().toIso8601String())
          .single();

      if (response == null) {
        return null;
      }

      // Kiểm tra đơn tối thiểu
      if (orderAmount < (response['don_gia_toi_thieu'] as num).toDouble()) {
        return {
          'valid': false,
          'message': 'Đơn hàng chưa đạt giá trị tối thiểu để áp dụng mã giảm giá',
        };
      }

      // Kiểm tra số lượng sử dụng
      if (response['so_luong_da_dung'] >= response['so_luong_ban_dau']) {
        return {
          'valid': false,
          'message': 'Mã giảm giá đã hết lượt sử dụng',
        };
      }

      return {
        'valid': true,
        'discount': response,
        'discount_amount': _calculateDiscountAmount(
          response['loai_giam_gia'],
          response['muc_giam_gia'],
          orderAmount,
        ),
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Mã giảm giá không hợp lệ',
      };
    }
  }

  // Tính số tiền được giảm
  static double _calculateDiscountAmount(String type, double value, double orderAmount) {
    if (type == 'percentage') {
      return (orderAmount * value / 100).roundToDouble();
    } else if (type == 'fixed') {
      return value > orderAmount ? orderAmount : value;
    }
    return 0;
  }

  // Cập nhật số lượng sử dụng mã giảm giá
  static Future<bool> updateDiscountUsage(String discountCode) async {
    try {
      // Lấy số lượng hiện tại
      final response = await _client
          .from('discounts')
          .select('so_luong_da_dung')
          .eq('code', discountCode)
          .single();

      final currentUsage = response['so_luong_da_dung'] as int;
      
      // Cập nhật số lượng mới
      await _client
          .from('discounts')
          .update({
            'so_luong_da_dung': currentUsage + 1,
          })
          .eq('code', discountCode);

      return true;
    } catch (e) {
      throw Exception('Failed to update discount usage: $e');
    }
  }
}
