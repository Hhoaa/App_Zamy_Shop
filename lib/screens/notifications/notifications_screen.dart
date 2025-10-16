import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../models/notification.dart';
import '../../services/supabase_notification_service.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final userNotifications =
            await SupabaseNotificationService.getUserNotifications(
              authProvider.user!.maNguoiDung,
            );
        setState(() {
          notifications = userNotifications;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải thông báo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Thông báo',
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Đánh dấu tất cả đã đọc',
              style: TextStyle(fontSize: 14, color: AppColors.accentRed),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? _buildEmptyNotifications()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có thông báo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chúng tôi sẽ thông báo cho bạn khi có cập nhật mới',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:
            notification.daDoc
                ? AppColors.cardBackground
                : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              notification.daDoc ? AppColors.borderLight : AppColors.accentRed,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.loaiThongBao),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification.loaiThongBao),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.tieuDe,
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                notification.daDoc ? FontWeight.normal : FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.noiDung,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.thoiGianTao),
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
        trailing:
            notification.daDoc
                ? null
                : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                  ),
                ),
        onTap: () {
          _markAsRead(notification.maThongBao);
          // Navigate to relevant screen based on notification type
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.info;
      case 'promotion':
        return AppColors.accentRed;
      case 'system':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final success = await SupabaseNotificationService.markAsRead(
        notificationId,
      );
      if (success) {
        setState(() {
          final index = notifications.indexWhere(
            (n) => n.maThongBao == notificationId,
          );
          if (index != -1) {
            notifications[index] = NotificationModel(
              maThongBao: notifications[index].maThongBao,
              maNguoiDung: notifications[index].maNguoiDung,
              tieuDe: notifications[index].tieuDe,
              noiDung: notifications[index].noiDung,
              loaiThongBao: notifications[index].loaiThongBao,
              daDoc: true,
              thoiGianTao: notifications[index].thoiGianTao,
              maDonHang: notifications[index].maDonHang,
              maKhuyenMai: notifications[index].maKhuyenMai,
            );
          }
        });
        // Sync unread badge on app bar
        if (mounted) {
          // ignore: use_build_context_synchronously
          final notifProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          await notifProvider.markAsRead(notificationId);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final success = await SupabaseNotificationService.markAllAsRead(
          authProvider.user!.maNguoiDung,
        );
        if (success) {
          setState(() {
            notifications =
                notifications.map((notification) {
                  return NotificationModel(
                    maThongBao: notification.maThongBao,
                    maNguoiDung: notification.maNguoiDung,
                    tieuDe: notification.tieuDe,
                    noiDung: notification.noiDung,
                    loaiThongBao: notification.loaiThongBao,
                    daDoc: true,
                    thoiGianTao: notification.thoiGianTao,
                    maDonHang: notification.maDonHang,
                    maKhuyenMai: notification.maKhuyenMai,
                  );
                }).toList();
          });
          // Sync unread badge on app bar
          final notifProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          await notifProvider.markAllAsRead(authProvider.user!.maNguoiDung);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã đánh dấu tất cả thông báo đã đọc'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }
}
