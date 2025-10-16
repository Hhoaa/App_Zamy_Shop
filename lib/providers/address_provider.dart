import 'package:flutter/foundation.dart';
import '../models/user_address.dart';
import '../services/supabase_address_service.dart';

class AddressProvider extends ChangeNotifier {
  List<UserAddress> _addresses = [];
  UserAddress? _defaultAddress;
  bool _isLoading = false;
  int? _currentUserId;

  List<UserAddress> get addresses => _addresses;
  UserAddress? get defaultAddress => _defaultAddress;
  bool get isLoading => _isLoading;
  bool get hasAddresses => _addresses.isNotEmpty;

  // Khởi tạo với user ID
  void initialize(int userId) {
    _currentUserId = userId;
    _loadAddresses();
  }

  // Load tất cả địa chỉ
  Future<void> _loadAddresses() async {
    if (_currentUserId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      final addresses = await SupabaseAddressService.getUserAddresses(_currentUserId!);
      final defaultAddr = await SupabaseAddressService.getDefaultAddress(_currentUserId!);
      
      _addresses = addresses;
      _defaultAddress = defaultAddr;
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh addresses
  Future<void> refreshAddresses() async {
    await _loadAddresses();
  }

  // Fetch addresses for specific user (public method)
  Future<void> fetchAddresses(int userId) async {
    _currentUserId = userId;
    await _loadAddresses();
  }

  // Thêm địa chỉ mới
  Future<bool> addAddress(UserAddress address) async {
    try {
      final newAddress = await SupabaseAddressService.addAddress(address);
      _addresses.add(newAddress);
      
      // Nếu đây là địa chỉ mặc định đầu tiên
      if (newAddress.isDefault) {
        _defaultAddress = newAddress;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding address: $e');
      return false;
    }
  }

  // Cập nhật địa chỉ
  Future<bool> updateAddress(UserAddress address) async {
    try {
      final updatedAddress = await SupabaseAddressService.updateAddress(address);
      
      final index = _addresses.indexWhere((addr) => addr.id == address.id);
      if (index != -1) {
        _addresses[index] = updatedAddress;
      }
      
      // Cập nhật default address nếu cần
      if (updatedAddress.isDefault) {
        _defaultAddress = updatedAddress;
      } else if (_defaultAddress?.id == updatedAddress.id) {
        _defaultAddress = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating address: $e');
      return false;
    }
  }

  // Xóa địa chỉ
  Future<bool> deleteAddress(int addressId) async {
    try {
      await SupabaseAddressService.deleteAddress(addressId);
      _addresses.removeWhere((addr) => addr.id == addressId);
      
      // Nếu xóa địa chỉ mặc định, tìm địa chỉ mặc định mới
      if (_defaultAddress?.id == addressId) {
        _defaultAddress = _addresses.isNotEmpty ? _addresses.first : null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting address: $e');
      return false;
    }
  }

  // Đặt địa chỉ làm mặc định
  Future<bool> setDefaultAddress(int addressId) async {
    if (_currentUserId == null) return false;
    
    try {
      await SupabaseAddressService.setDefaultAddress(_currentUserId!, addressId);
      
      // Cập nhật local state
      for (var address in _addresses) {
        address = address.copyWith(isDefault: address.id == addressId);
      }
      
      _defaultAddress = _addresses.firstWhere(
        (addr) => addr.id == addressId,
        orElse: () => _addresses.isNotEmpty ? _addresses.first : _addresses.first,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting default address: $e');
      return false;
    }
  }

  // Lấy địa chỉ theo ID
  UserAddress? getAddressById(int id) {
    try {
      return _addresses.firstWhere((addr) => addr.id == id);
    } catch (e) {
      return null;
    }
  }

  // Kiểm tra xem có địa chỉ mặc định không
  bool get hasDefaultAddress => _defaultAddress != null;

  // Lấy số lượng địa chỉ
  int get addressCount => _addresses.length;

  // Clear tất cả dữ liệu
  void clear() {
    _addresses.clear();
    _defaultAddress = null;
    _currentUserId = null;
    _isLoading = false;
    notifyListeners();
  }
}
