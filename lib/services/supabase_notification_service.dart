import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../config/supabase_config.dart';
import 'local_notification_service.dart';

class SupabaseNotificationService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy danh sách thông báo của user
  static Future<List<NotificationModel>> getUserNotifications(int userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('ma_nguoi_dung', userId)
          .order('thoi_gian_tao', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  // Đánh dấu thông báo đã đọc
  static Future<bool> markAsRead(int notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'da_doc': true})
          .eq('ma_thong_bao', notificationId);
      return true;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Đánh dấu tất cả thông báo đã đọc
  static Future<bool> markAllAsRead(int userId) async {
    try {
      await _client
          .from('notifications')
          .update({'da_doc': true})
          .eq('ma_nguoi_dung', userId);
      return true;
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Tạo thông báo mới
  static Future<bool> createNotification({
    required int userId,
    required String title,
    required String content,
    required String type,
    int? orderId,
    int? discountId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _client.from('notifications').insert({
        'ma_nguoi_dung': userId,
        'tieu_de': title,
        'noi_dung': content,
        'loai_thong_bao': type,
        'ma_don_hang': orderId,
        'ma_khuyen_mai': discountId,
        'du_lieu_bo_sung': additionalData,
        'da_doc': false,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Tạo thông báo đặt đơn hàng
  static Future<bool> createOrderNotification({
    required int userId,
    required int orderId,
    required String status,
  }) async {
    String title;
    String content;

    switch (status.toLowerCase()) {
      case 'pending':
        title = 'Đơn hàng đã được đặt';
        content = 'Đơn hàng của bạn đã được đặt thành công và đang chờ xác nhận.';
        break;
      case 'confirmed':
        title = 'Đơn hàng đã được xác nhận';
        content = 'Đơn hàng của bạn đã được xác nhận và đang được chuẩn bị.';
        break;
      case 'shipped':
        title = 'Đơn hàng đang được giao';
        content = 'Đơn hàng của bạn đang được giao đến địa chỉ đã cung cấp.';
        break;
      case 'delivered':
        title = 'Đơn hàng đã được giao';
        content = 'Đơn hàng của bạn đã được giao thành công. Cảm ơn bạn đã mua sắm!';
        break;
      case 'cancelled':
        title = 'Đơn hàng đã bị hủy';
        content = 'Đơn hàng của bạn đã bị hủy. Nếu có thắc mắc, vui lòng liên hệ hỗ trợ.';
        break;
      default:
        title = 'Cập nhật đơn hàng';
        content = 'Đơn hàng của bạn đã được cập nhật trạng thái.';
    }

    return await createNotification(
      userId: userId,
      title: title,
      content: content,
      type: 'order',
      orderId: orderId,
    );
  }

  // Xóa thông báo
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('ma_thong_bao', notificationId);
      return true;
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}