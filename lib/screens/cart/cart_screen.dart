import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../models/cart.dart';
import '../../services/supabase_cart_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../utils/currency_formatter.dart';
import '../checkout/checkout_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/ai_chat/bubble_visibility.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Set<int> selectedItems = {};
  double totalAmount = 0.0;
  bool isLoading = true;
  // Ẩn item ngay lập tức sau khi vuốt xoá để tránh lỗi Dismissible
  final Set<int> _hiddenItemIds = {};

  @override
  void initState() {
    super.initState();
    // Hide AI chat bubble on cart screen to avoid overlapping the buy button
    BubbleVisibility.hide();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        print('User is null, setting empty cart');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCart();
      final cart = cartProvider.cart;

      setState(() {
        isLoading = false;
      });

      // Tính tổng tiền sau khi load
      _calculateTotal();
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải giỏ hàng: $e')));
      }
    }
  }

  void _calculateTotal() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];
    double total = 0.0;
    for (var item in cartItems) {
      if (selectedItems.contains(item.maChiTietGioHang)) {
        total += item.giaTienTaiThoiDiemThem * item.soLuong;
        print(
          '[DEBUG] Added to total: ${item.giaTienTaiThoiDiemThem * item.soLuong}',
        );
      }
    }
    print('[DEBUG] Final total: $total');
    setState(() {
      totalAmount = total;
    });
  }

  bool get isAllSelected {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];
    return cartItems.isNotEmpty && selectedItems.length == cartItems.length;
  }

  void _toggleSelectAll(bool? value) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];

    setState(() {
      if (value == true) {
        selectedItems = cartItems.map((item) => item.maChiTietGioHang).toSet();
      } else {
        selectedItems.clear();
      }
      _calculateTotal();
    });
  }

  void _toggleSelectItem(int itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
      } else {
        selectedItems.add(itemId);
      }
    });

    _calculateTotal(); // Đảm bảo tính lại tổng tiền
  }

  Future<void> _updateQuantity(int itemId, int newQuantity) async {
    print(
      '[DEBUG] _updateQuantity called: itemId=$itemId, newQuantity=$newQuantity',
    );
    if (newQuantity <= 0) return;

    // Cập nhật UI ngay lập tức để có trải nghiệm mượt mà
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];
    final itemIndex = cartItems.indexWhere(
      (item) => item.maChiTietGioHang == itemId,
    );

    if (itemIndex != -1) {
      // Giới hạn theo tồn kho của biến thể
      final variantStock = cartItems[itemIndex].productVariant?.tonKho ?? 999999;
      if (newQuantity > variantStock) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chỉ còn $variantStock sản phẩm trong kho')),
          );
        }
        return;
      }
      // Cập nhật local state trước
      cartProvider.updateItemQuantity(itemId, newQuantity);
      print('[DEBUG] Updated local state immediately');

      // Tính lại tổng tiền ngay
      _calculateTotal();
    }

    // Sau đó sync với database (background)
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        print('[DEBUG] User is null');
        return;
      }

      print('[DEBUG] Calling SupabaseCartService.updateQuantity...');
      await SupabaseCartService.updateQuantity(
        cartDetailId: itemId,
        quantity: newQuantity,
      );
      print('[DEBUG] SupabaseCartService.updateQuantity successful');

      // Reload cart từ CartProvider để đảm bảo sync
      await cartProvider.loadCart();
      print('[DEBUG] Synced with database');
    } catch (e) {
      print('[DEBUG] Error updating quantity: $e');
      // Revert local changes nếu có lỗi
      await cartProvider.loadCart();
      _calculateTotal();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật số lượng: $e')));
    }
  }

  Future<void> _removeItem(int itemId) async {
    print('[DEBUG] _removeItem called: $itemId');
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        print('[DEBUG] User is null');
        return;
      }

      print('[DEBUG] Calling SupabaseCartService.removeFromCart...');
      await SupabaseCartService.removeFromCart(itemId);
      print('[DEBUG] SupabaseCartService.removeFromCart successful');

      // Reload cart từ CartProvider thay vì cập nhật local state
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCart();
      print('[DEBUG] Reloaded cart from CartProvider');

      // Cập nhật local state với delay để tránh conflict với Dismissible
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        setState(() {
          selectedItems.remove(itemId);
          print('[DEBUG] Removed item from selection');
        });

        _calculateTotal();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa sản phẩm khỏi giỏ hàng'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[DEBUG] Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa sản phẩm: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final items = cartProvider.cartDetails;
              if (items.isNotEmpty) {
                return TextButton(
                  onPressed: () async {
                    final hasSelection = selectedItems.isNotEmpty;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(hasSelection ? 'Xóa mục đã chọn' : 'Xóa tất cả'),
                        content: Text(hasSelection
                            ? 'Bạn có chắc muốn xóa các sản phẩm đã chọn khỏi giỏ hàng?'
                            : 'Bạn có chắc muốn xóa toàn bộ giỏ hàng?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    final user = await SupabaseAuthService.getCurrentUser();
                    if (user == null) return;

                    try {
                      if (hasSelection) {
                        await SupabaseCartService.removeSelectedFromCart(user.maNguoiDung, selectedItems);
                        setState(() {
                          _hiddenItemIds.addAll(selectedItems);
                          selectedItems.clear();
                          _calculateTotal();
                        });
                      } else {
                        await SupabaseCartService.clearCart(user.maNguoiDung);
                        setState(() {
                          _hiddenItemIds.addAll(items.map((e) => e.maChiTietGioHang));
                          selectedItems.clear();
                          totalAmount = 0.0;
                        });
                      }
                      await cartProvider.loadCart();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi xóa: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Xóa',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<CartProvider>(
                builder: (context, cartProvider, _) {
                  final sourceItems = cartProvider.cartDetails;
                  final items = sourceItems.where((d) => !_hiddenItemIds.contains(d.maChiTietGioHang)).toList();
                  if (items.isEmpty) {
                    return _buildEmptyCart();
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: items.length,
                          separatorBuilder:
                              (context, index) => Container(
                                height: 8,
                                color: AppColors.background,
                              ),
                          itemBuilder: (context, index) {
                            return _buildCartItem(items[index]);
                          },
                        ),
                      ),
                      _buildBottomBar(),
                    ],
                  );
                },
              ),
    );
  }

  @override
  void dispose() {
    // Restore chat bubble visibility when leaving cart screen
    BubbleVisibility.show();
    super.dispose();
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Giỏ hàng trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm sản phẩm vào giỏ hàng nhé!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartDetail item) {
    final isSelected = selectedItems.contains(item.maChiTietGioHang);

    return Dismissible(
      key: ValueKey(item.maChiTietGioHang),
      direction: DismissDirection.endToStart,
      resizeDuration: const Duration(milliseconds: 200),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Xác nhận xóa'),
                content: const Text(
                  'Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) async {
        setState(() {
          _hiddenItemIds.add(item.maChiTietGioHang);
          selectedItems.remove(item.maChiTietGioHang);
        });
        await _removeItem(item.maChiTietGioHang);
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleSelectItem(item.maChiTietGioHang),
              activeColor: AppColors.accentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Product Image
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:
                    item.productVariant?.product != null &&
                            item.productVariant!.product!.hinhAnh.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: item.productVariant!.product!.hinhAnh.first,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.image_not_supported,
                                color: AppColors.mediumGray,
                              ),
                        )
                        : const Icon(Icons.image, color: AppColors.mediumGray),
              ),
            ),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    item.productVariant?.product?.tenSanPham ?? 'Sản phẩm',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Variant Info (Size & Color)
                  Row(
                    children: [
                      if (item.productVariant?.color != null)
                        Text(
                          'Phân loại: ${item.productVariant!.color!.tenMau}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (item.productVariant?.size != null) ...[
                        if (item.productVariant?.color != null)
                          const Text(
                            ', ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        Text(
                          item.productVariant!.size!.tenSize,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price and Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price
                      Text(
                        CurrencyFormatter.formatVND(
                          item.giaTienTaiThoiDiemThem,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentRed,
                        ),
                      ),
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (item.soLuong > 1) {
                                  _updateQuantity(
                                    item.maChiTietGioHang,
                                    item.soLuong - 1,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color:
                                      item.soLuong > 1
                                          ? AppColors.textSecondary
                                          : AppColors.mediumGray,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Center(
                                child: Text(
                                  '${item.soLuong}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final stock = item.productVariant?.tonKho ?? 999999;
                                final next = item.soLuong + 1;
                                if (next > stock) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Chỉ còn $stock sản phẩm trong kho')),
                                  );
                                  return;
                                }
                                _updateQuantity(
                                  item.maChiTietGioHang,
                                  next,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = selectedItems.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Select All Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: isAllSelected,
                    onChanged: _toggleSelectAll,
                    activeColor: AppColors.accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    'Tất cả',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatVND(totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        selectedCount > 0
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    selectedCartDetailIds: selectedItems,
                                  ),
                                ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      disabledBackgroundColor: AppColors.mediumGray,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Mua hàng ($selectedCount)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
