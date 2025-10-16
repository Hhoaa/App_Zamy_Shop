import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/cart.dart';
import '../services/supabase_cart_service.dart';
import '../services/supabase_auth_service.dart';

class CartItem {
  final Product product;
  final int sizeId;
  final int colorId;
  final int quantity;
  final double price;

  CartItem({
    required this.product,
    required this.sizeId,
    required this.colorId,
    required this.quantity,
    required this.price,
  });

  double get totalPrice => price * quantity;
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  Cart? _cart;
  bool _isLoading = false;
  String? _lastErrorMessage;

  List<CartItem> get items => _items;
  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get lastErrorMessage => _lastErrorMessage;
  // Expose cart details for screens that need rich variant info
  List<CartDetail> get cartDetails => _cart?.cartDetails ?? [];

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalFromDb => (_cart?.cartDetails ?? []).fold(
    0.0,
    (sum, d) => sum + (d.giaTienTaiThoiDiemThem * d.soLuong),
  );

  // Load cart from database
  Future<void> loadCart() async {
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      _isLoading = true;
      notifyListeners();

      _cart = await SupabaseCartService.getUserCart(user.maNguoiDung);
      if (_cart != null) {
        _convertCartDetailsToItems(_cart!);
      }
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert CartDetails to CartItems for UI compatibility
  void _convertCartDetailsToItems(Cart cart) {
    _items.clear();
    for (final detail in cart.cartDetails) {
      final product = detail.product as Product?;
      final sizeId = detail.productVariant?.maSize;
      final colorId = detail.productVariant?.maMau;

      if (product != null && sizeId != null && colorId != null) {
        _items.add(
          CartItem(
            product: product,
            sizeId: sizeId,
            colorId: colorId,
            quantity: detail.soLuong,
            price: detail.giaTienTaiThoiDiemThem,
          ),
        );
      }
    }
    notifyListeners();
  }

  Future<bool> addToCart(
    Product product,
    int sizeId,
    int colorId,
    int quantity,
  ) async {
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        print('User not logged in');
        return false;
      }

      // Add to database
      final success = await SupabaseCartService.addToCart(
        userId: user.maNguoiDung,
        productId: product.maSanPham,
        sizeId: sizeId,
        colorId: colorId,
        quantity: quantity,
        price: product.giaBan,
      );

      if (success) {
        _lastErrorMessage = null;
        // Reload cart from database to get updated data
        await loadCart();
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('Error adding to cart: $e');
      _lastErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCartDetail(int cartDetailId) async {
    try {
      final removed = await SupabaseCartService.removeFromCart(cartDetailId);
      if (removed) {
        await loadCart();
      }
      return removed;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCartDetailQuantity(int cartDetailId, int quantity) async {
    try {
      final updated = await SupabaseCartService.updateQuantity(
        cartDetailId: cartDetailId,
        quantity: quantity,
      );
      if (updated) {
        _lastErrorMessage = null;
        await loadCart();
      }
      return updated;
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Cập nhật số lượng item trong local state (để UI update nhanh)
  void updateItemQuantity(int itemId, int newQuantity) {
    if (_cart != null) {
      final itemIndex = _cart!.cartDetails.indexWhere(
        (item) => item.maChiTietGioHang == itemId,
      );

      if (itemIndex != -1) {
        // Tạo CartDetail mới với số lượng đã cập nhật
        final oldItem = _cart!.cartDetails[itemIndex];
        final updatedItem = CartDetail(
          maChiTietGioHang: oldItem.maChiTietGioHang,
          maGioHang: oldItem.maGioHang,
          maBienTheSanPham: oldItem.maBienTheSanPham,
          soLuong: newQuantity,
          giaTienTaiThoiDiemThem: oldItem.giaTienTaiThoiDiemThem,
          productVariant: oldItem.productVariant,
        );

        // Cập nhật cart details
        _cart!.cartDetails[itemIndex] = updatedItem;
        notifyListeners();
      }
    }
  }
}
