import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../order/order_screen.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../store/free_store_info_screen.dart';
import '../news/news_screen.dart';
import '../policy/shipping_policy_screen.dart';
import '../policy/size_guide_screen.dart';
import '../address/address_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.user == null) {
            return _buildLoginPrompt();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildMenuItems(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Đăng nhập để sử dụng đầy đủ tính năng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Quản lý đơn hàng, yêu thích và nhiều hơn nữa',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Đăng nhập',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            size: AppButtonSize.large,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Đăng ký',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            width: double.infinity,
            backgroundColor: Colors.transparent,
            textColor: AppColors.accentRed,
            borderColor: AppColors.accentRed,
            size: AppButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return SizedBox(
          width: double.infinity,
          child: AppCard(
            child: Column(
              children: [
              GestureDetector(
                onTap: () => _pickAndUploadAvatar(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.accentRed,
                      backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                          ? NetworkImage(user.avatar!)
                          : null,
                      child: user?.avatar == null || user!.avatar!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.camera_alt, size: 18, color: AppColors.accentRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.tenNguoiDung ?? 'Chưa có tên',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Chưa có email',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (user?.soDienThoai != null && user!.soDienThoai!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.soDienThoai!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Chỉnh sửa thông tin',
                  type: AppButtonType.secondary,
                  onPressed: () => _showEditProfileDialog(),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildMenuItems() {
    return AppCard(
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Đơn hàng của tôi',
            subtitle: 'Xem lịch sử đơn hàng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.favorite_outline,
            title: 'Sản phẩm yêu thích',
            subtitle: 'Danh sách sản phẩm đã lưu',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Quản lý địa chỉ',
            subtitle: 'Thêm, sửa, xóa địa chỉ giao hàng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressManagementScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            subtitle: 'Cập nhật đơn hàng và khuyến mãi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.smart_toy_outlined,
            title: 'AI Tư vấn thời trang',
            subtitle: 'Chat với AI để được tư vấn',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.chat_outlined,
            title: 'Hỗ trợ khách hàng',
            subtitle: 'Chat với Admin',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen(adminUserId: 1)),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.store_outlined,
            title: 'Thông tin cửa hàng',
            subtitle: 'Địa chỉ và giờ hoạt động',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FreeStoreInfoScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.newspaper_outlined,
            title: 'Tin tức',
            subtitle: 'Cập nhật mới nhất',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewsScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.local_shipping_outlined,
            title: 'Chính sách vận chuyển',
            subtitle: 'Thông tin giao hàng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShippingPolicyScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.straighten_outlined,
            title: 'Hướng dẫn chọn size',
            subtitle: 'Bảng size và cách đo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SizeGuideScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.accentRed,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return AppButton(
      text: 'Đăng xuất',
      onPressed: _handleLogout,
      width: double.infinity,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      size: AppButtonSize.large,
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;
    
    final nameController = TextEditingController(text: user.tenNguoiDung);
    final phoneController = TextEditingController(text: user.soDienThoai ?? '');
    final addressController = TextEditingController(text: user.diaChi ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 11,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _updateProfile(
              nameController.text,
              phoneController.text,
              addressController.text,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String name, String phone, String address) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;
      
      // Update user profile in Supabase
      await SupabaseAuthService.updateUserProfile(
        authProvider.user!.maNguoiDung,
        name: name,
        phone: phone,
        address: address,
      );
      
      // Refresh user data
      await authProvider.checkCurrentUser();
      
      Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      if (currentUser == null) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      // Upload to Supabase Storage
      final url = await SupabaseAuthService.uploadUserAvatar(
        userId: currentUser.maNguoiDung,
        data: bytes,
        contentType: picked.mimeType ?? 'image/jpeg',
      );

      // Update profile with avatar URL
      await SupabaseAuthService.updateUserProfile(
        currentUser.maNguoiDung,
        avatarUrl: url,
      );

      // Refresh user from backend
      await authProvider.checkCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật ảnh đại diện: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      setState(() => isLoading = true);
      
      await Provider.of<AuthProvider>(context, listen: false).logout();
      
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng xuất thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}