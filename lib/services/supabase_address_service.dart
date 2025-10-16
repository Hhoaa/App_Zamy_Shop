import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_address.dart';
import '../config/supabase_config.dart';

class SupabaseAddressService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy tất cả địa chỉ của user
  static Future<List<UserAddress>> getUserAddresses(int userId) async {
    try {
      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserAddress.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user addresses: $e');
      throw Exception('Không thể lấy danh sách địa chỉ: $e');
    }
  }

  // Lấy địa chỉ mặc định của user
  static Future<UserAddress?> getDefaultAddress(int userId) async {
    try {
      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;
      return UserAddress.fromJson(response);
    } catch (e) {
      print('Error getting default address: $e');
      return null;
    }
  }

  // Thêm địa chỉ mới
  static Future<UserAddress> addAddress(UserAddress address) async {
    try {
      final response = await _client
          .from('user_addresses')
          .insert(address.toJsonForInsert())
          .select()
          .single();

      return UserAddress.fromJson(response);
    } catch (e) {
      print('Error adding address: $e');
      throw Exception('Không thể thêm địa chỉ: $e');
    }
  }

  // Cập nhật địa chỉ
  static Future<UserAddress> updateAddress(UserAddress address) async {
    try {
      final response = await _client
          .from('user_addresses')
          .update(address.toJsonForInsert())
          .eq('id', address.id)
          .select()
          .single();

      return UserAddress.fromJson(response);
    } catch (e) {
      print('Error updating address: $e');
      throw Exception('Không thể cập nhật địa chỉ: $e');
    }
  }

  // Xóa địa chỉ
  static Future<void> deleteAddress(int addressId) async {
    try {
      await _client
          .from('user_addresses')
          .delete()
          .eq('id', addressId);
    } catch (e) {
      print('Error deleting address: $e');
      throw Exception('Không thể xóa địa chỉ: $e');
    }
  }

  // Đặt địa chỉ làm mặc định
  static Future<void> setDefaultAddress(int userId, int addressId) async {
    try {
      // Set tất cả địa chỉ của user thành false
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      // Set địa chỉ được chọn thành true
      await _client
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', addressId);
    } catch (e) {
      print('Error setting default address: $e');
      throw Exception('Không thể đặt địa chỉ mặc định: $e');
    }
  }

  // Kiểm tra xem user có địa chỉ nào không
  static Future<bool> hasAddresses(int userId) async {
    try {
      final response = await _client
          .from('user_addresses')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking if user has addresses: $e');
      return false;
    }
  }

  // Lấy số lượng địa chỉ của user
  static Future<int> getAddressCount(int userId) async {
    try {
      final response = await _client
          .from('user_addresses')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting address count: $e');
      return 0;
    }
  }

  // Validate địa chỉ
  static bool validateAddress(UserAddress address) {
    if (address.fullName.trim().isEmpty) return false;
    if (address.phone.trim().isEmpty) return false;
    if (address.addressLine1.trim().isEmpty) return false;
    if (address.city.trim().isEmpty) return false;
    
    // Validate phone number (basic)
    final phoneRegex = RegExp(r'^[0-9\s\-\+\(\)]+$');
    if (!phoneRegex.hasMatch(address.phone)) return false;
    
    return true;
  }

  // Tạo địa chỉ mẫu cho user mới
  static Future<UserAddress?> createSampleAddress(int userId) async {
    try {
      // Kiểm tra xem user đã có địa chỉ chưa
      final hasAddress = await hasAddresses(userId);
      if (hasAddress) return null;

      // Tạo địa chỉ mẫu
      final sampleAddress = UserAddress(
        id: 0, // Sẽ được tạo bởi database
        userId: userId,
        fullName: 'Tên của bạn',
        phone: '0123 456 789',
        addressLine1: 'Nhập địa chỉ của bạn',
        city: 'TP.HCM',
        isDefault: true,
        addressType: 'home',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await addAddress(sampleAddress);
    } catch (e) {
      print('Error creating sample address: $e');
      return null;
    }
  }
}
