import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../config/supabase_config.dart';
import 'supabase_notification_service.dart';

class SupabaseOrderService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy ID của trạng thái "Chờ xác nhận"
  static Future<int?> _getPendingStatusId() async {
    try {
      final response =
          await _client
              .from('order_statuses')
              .select('ma_trang_thai_don_hang')
              .eq('ten_trang_thai', 'Chờ xác nhận')
              .single();

      return response['ma_trang_thai_don_hang'] as int?;
    } catch (e) {
      print('Error getting pending status ID: $e');
      return null;
    }
  }

  // Lấy danh sách đơn hàng của user
  static Future<List<Order>> getUserOrders(int userId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            order_details:order_details(
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
            ),
            order_status:ma_trang_thai_don_hang(*)
          ''')
          .eq('ma_nguoi_dung', userId)
          .order('ngay_dat_hang', ascending: false);

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Lấy chi tiết đơn hàng
  static Future<Order?> getOrderById(int orderId) async {
    try {
      final response =
          await _client
              .from('orders')
              .select('''
            *,
            order_details:order_details(
              *,
              product_variant:ma_bien_the_san_pham(
                *,
                product:ma_san_pham(*),
                size:ma_size(*),
                color:ma_mau(*)
              )
            ),
            order_status:ma_trang_thai_don_hang(*)
          ''')
              .eq('ma_don_hang', orderId)
              .maybeSingle();

      if (response == null) return null;
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Tạo đơn hàng mới
  static Future<int?> createOrder({
    required int userId,
    required List<Map<String, dynamic>> items,
    // Tên tham số theo màn hình checkout
    required String diaChiGiaoHang,
    double? tongGiaTriDonHang,
    String? ghiChu,
    int? maGiamGia,
  }) async {
    try {
      print('[DEBUG] SupabaseOrderService: Bắt đầu tạo đơn hàng...');
      print('[DEBUG] Thông tin đầu vào:');
      print('   - User ID: $userId');
      print('   - Địa chỉ: $diaChiGiaoHang');
      print('   - Tổng tiền: $tongGiaTriDonHang');
      print('   - Ghi chú: $ghiChu');
      print('   - Mã giảm giá: $maGiamGia');
      print('   - Số items: ${items.length}');

      // Lấy ID của trạng thái "Chờ xác nhận"
      print('[DEBUG] Lấy ID trạng thái "Chờ xác nhận"...');
      final pendingStatusId = await _getPendingStatusId();
      print('[DEBUG] ID trạng thái: $pendingStatusId');

      // 1) Kiểm tra tồn kho và trừ tồn kho theo từng biến thể
      print('[DEBUG] Kiểm tra và trừ tồn kho...');
      // Gộp số lượng theo biến thể phòng trùng
      final Map<int, int> variantToQty = {};
      for (final raw in items) {
        final int variantId =
            (raw['ma_bien_the_san_pham'] ?? raw['variantId']) as int;
        final int qty = (raw['so_luong_mua'] ?? raw['quantity']) as int;
        variantToQty.update(variantId, (old) => old + qty, ifAbsent: () => qty);
      }

      // Kiểm tra tồn kho hiện tại
      for (final entry in variantToQty.entries) {
        final variantId = entry.key;
        final qty = entry.value;
        final stockRow =
            await _client
                .from('product_variants')
                .select('ton_kho')
                .eq('ma_bien_the', variantId)
                .single();
        final currentStock = stockRow['ton_kho'] as int;
        if (currentStock < qty) {
          throw Exception('Sản phẩm không đủ hàng (variant $variantId)');
        }
      }

      // Trừ tồn kho có điều kiện (đơn giản, có thể xảy ra race condition nhẹ)
      final List<int> decrementedVariants = [];
      final Map<int, int> prevStocks = {};
      for (final entry in variantToQty.entries) {
        final variantId = entry.key;
        final qty = entry.value;
        final stockRow =
            await _client
                .from('product_variants')
                .select('ton_kho')
                .eq('ma_bien_the', variantId)
                .single();
        final currentStock = stockRow['ton_kho'] as int;
        if (currentStock < qty) {
          // Rollback trước đó nếu có
          for (final v in decrementedVariants) {
            final rollbackQty = variantToQty[v] ?? 0;
            final before = prevStocks[v] ?? 0;
            await _client
                .from('product_variants')
                .update({'ton_kho': before})
                .eq('ma_bien_the', v);
          }
          throw Exception('Không thể trừ tồn kho cho biến thể $variantId');
        }
        prevStocks[variantId] = currentStock;
        final newStock = currentStock - qty;
        await _client
            .from('product_variants')
            .update({'ton_kho': newStock})
            .eq('ma_bien_the', variantId);
        decrementedVariants.add(variantId);
      }

      // 2) Tạo đơn hàng
      print('[DEBUG] Tạo đơn hàng trong database...');
      final orderResponse =
          await _client
              .from('orders')
              .insert({
                'ma_nguoi_dung': userId,
                'dia_chi_giao_hang': diaChiGiaoHang,
                'ma_giam_gia': maGiamGia,
                'tong_gia_tri_don_hang': tongGiaTriDonHang,
                'ghi_chu': ghiChu,
                'ma_trang_thai_don_hang':
                    pendingStatusId, // Set trạng thái "Chờ xác nhận"
              })
              .select('ma_don_hang')
              .single();

      final orderId = orderResponse['ma_don_hang'];
      print('[DEBUG] Tạo đơn hàng thành công! Order ID: $orderId');

      // 3) Tạo order details
      print('[DEBUG] Tạo order details...');
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        print('[DEBUG] Tạo order detail ${i + 1}/${items.length}:');
        print(
          '   - Ma bien the: ${item['ma_bien_the_san_pham'] ?? item['variantId']}',
        );
        print('   - So luong: ${item['so_luong_mua'] ?? item['quantity']}');
        print(
          '   - Thanh tien: ${item['thanh_tien'] ?? (item['price'] != null && item['quantity'] != null ? item['price'] * item['quantity'] : null)}',
        );

        await _client.from('order_details').insert({
          'ma_don_hang': orderId,
          'ma_bien_the_san_pham':
              item['ma_bien_the_san_pham'] ?? item['variantId'],
          'thanh_tien':
              item['thanh_tien'] ??
              (item['price'] != null && item['quantity'] != null
                  ? item['price'] * item['quantity']
                  : null),
          'so_luong_mua': item['so_luong_mua'] ?? item['quantity'],
        });
      }
      print('[DEBUG] Tạo order details thành công!');

      // Tạo thông báo đặt đơn hàng
      try {
        print('[DEBUG] Tạo thông báo đặt đơn hàng...');
        await SupabaseNotificationService.createOrderNotification(
          userId: userId,
          orderId: orderId,
          status: 'pending',
        );
        print('[DEBUG] Tạo thông báo thành công!');
      } catch (e) {
        // Log error nhưng không throw để không ảnh hưởng đến việc tạo đơn hàng
        print('[DEBUG] Lỗi tạo thông báo: $e');
      }

      print('[DEBUG] Hoàn thành tạo đơn hàng! Order ID: $orderId');
      return orderId;
    } catch (e, stackTrace) {
      print('[DEBUG] SupabaseOrderService: Lỗi tạo đơn hàng: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      throw Exception('Failed to create order: $e');
    }
  }

  // Cập nhật trạng thái đơn hàng
  static Future<bool> updateOrderStatus(int orderId, int statusId) async {
    try {
      await _client
          .from('orders')
          .update({'ma_trang_thai_don_hang': statusId})
          .eq('ma_don_hang', orderId);

      return true;
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cập nhật ghi chú đơn hàng
  static Future<bool> updateOrderNote(int orderId, String note) async {
    try {
      await _client
          .from('orders')
          .update({'ghi_chu': note})
          .eq('ma_don_hang', orderId);

      return true;
    } catch (e) {
      throw Exception('Failed to update order note: $e');
    }
  }

  // Hủy đơn hàng
  static Future<bool> cancelOrder(int orderId, {String? reason}) async {
    try {
      // Fetch order owner id to notify later
      final orderRow =
          await _client
              .from('orders')
              .select('ma_nguoi_dung')
              .eq('ma_don_hang', orderId)
              .maybeSingle();
      final userId = orderRow != null ? orderRow['ma_nguoi_dung'] as int : null;
      // Lấy ID của trạng thái "Đã hủy" từ order_statuses table
      final cancelledStatusResponse =
          await _client
              .from('order_statuses')
              .select('ma_trang_thai_don_hang')
              .eq('ten_trang_thai', 'Đã hủy')
              .maybeSingle();

      if (cancelledStatusResponse != null) {
        await _client
            .from('orders')
            .update({
              'ma_trang_thai_don_hang':
                  cancelledStatusResponse['ma_trang_thai_don_hang'],
              if (reason != null && reason.isNotEmpty)
                'ghi_chu': 'Hủy đơn: ' + reason,
            })
            .eq('ma_don_hang', orderId);
      }

      // Hoàn lại tồn kho cho các sản phẩm trong đơn
      final orderDetails = await _client
          .from('order_details')
          .select('ma_bien_the_san_pham, so_luong_mua')
          .eq('ma_don_hang', orderId);
      for (final d in (orderDetails as List)) {
        final int variantId = d['ma_bien_the_san_pham'] as int;
        final int qty = d['so_luong_mua'] as int;
        final stockRow =
            await _client
                .from('product_variants')
                .select('ton_kho')
                .eq('ma_bien_the', variantId)
                .single();
        final currentStock = stockRow['ton_kho'] as int;
        await _client
            .from('product_variants')
            .update({'ton_kho': currentStock + qty})
            .eq('ma_bien_the', variantId);
      }

      // Create notification
      if (userId != null) {
        await SupabaseNotificationService.createNotification(
          userId: userId,
          title: 'Đơn hàng đã bị hủy',
          content:
              reason != null && reason.isNotEmpty
                  ? reason
                  : 'Đơn hàng của bạn đã bị hủy',
          type: 'order',
          orderId: orderId,
        );
      }

      return true;
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Tạo yêu cầu hoàn hàng/hoàn trả
  static Future<bool> requestReturn(
    int orderId, {
    required String reason,
  }) async {
    try {
      final orderRow =
          await _client
              .from('orders')
              .select('ma_nguoi_dung')
              .eq('ma_don_hang', orderId)
              .maybeSingle();
      final userId = orderRow != null ? orderRow['ma_nguoi_dung'] as int : null;
      // Cố tìm trạng thái phù hợp nếu có
      final statuses = await _client
          .from('order_statuses')
          .select('ma_trang_thai_don_hang, ten_trang_thai');
      final match = (statuses as List?)
          ?.cast<Map<String, dynamic>>()
          .firstWhere(
            (e) =>
                (e['ten_trang_thai'] as String).toLowerCase().contains('hoàn'),
            orElse: () => {},
          );

      final updateData = <String, dynamic>{
        if (match != null && match.isNotEmpty)
          'ma_trang_thai_don_hang': match['ma_trang_thai_don_hang'],
        'ghi_chu': 'Yêu cầu hoàn hàng: ' + reason,
      };

      await _client
          .from('orders')
          .update(updateData)
          .eq('ma_don_hang', orderId);

      // Hoàn lại tồn kho khi yêu cầu hoàn hàng (tùy chính sách, ở đây hoàn ngay)
      final orderDetails = await _client
          .from('order_details')
          .select('ma_bien_the_san_pham, so_luong_mua')
          .eq('ma_don_hang', orderId);
      for (final d in (orderDetails as List)) {
        final int variantId = d['ma_bien_the_san_pham'] as int;
        final int qty = d['so_luong_mua'] as int;
        final stockRow =
            await _client
                .from('product_variants')
                .select('ton_kho')
                .eq('ma_bien_the', variantId)
                .single();
        final currentStock = stockRow['ton_kho'] as int;
        await _client
            .from('product_variants')
            .update({'ton_kho': currentStock + qty})
            .eq('ma_bien_the', variantId);
      }

      // Create notification
      if (userId != null) {
        await SupabaseNotificationService.createNotification(
          userId: userId,
          title: 'Yêu cầu hoàn hàng',
          content: reason,
          type: 'order',
          orderId: orderId,
        );
      }

      return true;
    } catch (e) {
      throw Exception('Failed to request return: $e');
    }
  }
}
