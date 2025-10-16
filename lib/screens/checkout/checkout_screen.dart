import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../services/supabase_order_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_cart_service.dart';
import '../../services/supabase_discount_service.dart';
import '../../services/vnpay_service.dart';
import '../../config/supabase_config.dart';
import '../order/order_screen.dart';
import '../address/address_selection_screen.dart';
import '../address/add_edit_address_screen.dart';
import '../../models/cart.dart';
import '../../models/user_address.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.selectedCartDetailIds});

  final Set<int>? selectedCartDetailIds; // chỉ đặt hàng các item được chọn

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'COD';
  final TextEditingController _notesController = TextEditingController();
  UserAddress? _selectedAddress;
  String? _selectedDiscountId;
  Map<String, dynamic>? _selectedDiscount;
  List<Map<String, dynamic>> _availableDiscounts = [];
  bool _submitting = false;
  bool _loadingDiscounts = false;

  // Helper: lấy danh sách cart details nguồn theo lựa chọn
  List<CartDetail> _getSourceDetails(CartProvider cart) {
    final all = cart.cartDetails;
    final ids = widget.selectedCartDetailIds;
    if (ids == null || ids.isEmpty) return all;
    return all.where((d) => ids.contains(d.maChiTietGioHang)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadDiscounts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      await addressProvider.fetchAddresses(authProvider.user!.maNguoiDung);

      // Tự động chọn địa chỉ mặc định hoặc địa chỉ đầu tiên
      if (addressProvider.addresses.isNotEmpty) {
        final defaultAddress = addressProvider.addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addressProvider.addresses.first,
        );
        setState(() {
          _selectedAddress = defaultAddress;
        });
      }
    }
  }

  // Kiểm tra mã giảm giá có hợp lệ không
  String? _validateDiscount(Map<String, dynamic> discount, double orderAmount) {
    // Kiểm tra đơn tối thiểu
    final minOrder = discount['don_gia_toi_thieu'] as num?;
    if (minOrder != null && orderAmount < minOrder.toDouble()) {
      return 'Đơn hàng chưa đạt giá trị tối thiểu ${CurrencyFormatter.formatVND(minOrder.toDouble())}';
    }

    // Kiểm tra số lượng còn lại
    final totalQuantity = discount['so_luong_ban_dau'] as int? ?? 0;
    final usedQuantity = discount['so_luong_da_dung'] as int? ?? 0;
    if (totalQuantity > 0 && usedQuantity >= totalQuantity) {
      return 'Mã giảm giá đã hết lượt sử dụng';
    }

    // Kiểm tra thời gian hiệu lực
    final startDate = discount['ngay_bat_dau'] as String?;
    final endDate = discount['ngay_ket_thuc'] as String?;
    final now = DateTime.now();

    if (startDate != null) {
      final start = DateTime.parse(startDate);
      if (now.isBefore(start)) {
        return 'Mã giảm giá chưa có hiệu lực';
      }
    }

    if (endDate != null) {
      final end = DateTime.parse(endDate);
      if (now.isAfter(end)) {
        return 'Mã giảm giá đã hết hạn';
      }
    }

    return null; // Hợp lệ
  }

  // Tính số tiền được giảm
  double _calculateDiscountAmount(double orderAmount) {
    if (_selectedDiscount == null) return 0.0;

    // Kiểm tra validation trước khi tính
    final validationError = _validateDiscount(_selectedDiscount!, orderAmount);
    if (validationError != null) {
      return 0.0;
    }

    final discountType = _selectedDiscount!['loai_giam_gia'] as String;
    final discountValue =
        (_selectedDiscount!['muc_giam_gia'] as num).toDouble();

    if (discountType == 'percentage') {
      return (orderAmount * discountValue / 100).roundToDouble();
    } else if (discountType == 'fixed') {
      return discountValue > orderAmount ? orderAmount : discountValue;
    }
    return 0.0;
  }

  // Tính tổng tiền sau giảm giá
  double _calculateTotalAfterDiscount(double orderAmount) {
    final discountAmount = _calculateDiscountAmount(orderAmount);
    return orderAmount - discountAmount;
  }

  Future<void> _placeOrder() async {
    print('[DEBUG] Bắt đầu đặt đơn hàng...');
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Kiểm tra địa chỉ
    if (_selectedAddress == null) {
      print('[DEBUG] Lỗi: Chưa chọn địa chỉ giao hàng');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ giao hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (auth.user == null || cartProvider.cartDetails.isEmpty) {
      print('[DEBUG] Lỗi: Giỏ hàng trống hoặc chưa đăng nhập');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng trống hoặc chưa đăng nhập')),
      );
      return;
    }

    try {
      setState(() => _submitting = true);

      final userId = auth.user!.maNguoiDung;
      // Lấy source theo lựa chọn
      final source = _getSourceDetails(cartProvider);
      if (source.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn sản phẩm để đặt hàng')),
        );
        return;
      }
      // Merge trùng variant để tránh nhân đôi
      final mergedDetails = <int, CartDetail>{};
      for (final d in source) {
        final key = d.maBienTheSanPham;
        if (mergedDetails.containsKey(key)) {
          final old = mergedDetails[key]!;
          mergedDetails[key] = CartDetail(
            maChiTietGioHang: old.maChiTietGioHang,
            maGioHang: old.maGioHang,
            maBienTheSanPham: old.maBienTheSanPham,
            soLuong: old.soLuong + d.soLuong,
            giaTienTaiThoiDiemThem: old.giaTienTaiThoiDiemThem,
            productVariant: old.productVariant,
          );
        } else {
          mergedDetails[key] = d;
        }
      }
      final details = mergedDetails.values.toList();
      final total = details.fold<double>(
        0.0,
        (s, it) => s + it.giaTienTaiThoiDiemThem * it.soLuong,
      );
      // Kiểm tra tồn kho trước khi tiếp tục
      final isStockOk = await _validateStock(details);
      if (!isStockOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Một số sản phẩm không đủ hàng. Vui lòng điều chỉnh số lượng.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Tính tổng tiền sau giảm giá
      double finalTotal = total;
      if (_selectedDiscount != null) {
        final validationError = _validateDiscount(_selectedDiscount!, total);
        if (validationError == null) {
          final discountAmount = _calculateDiscountAmount(total);
          finalTotal = total - discountAmount;
        }
      }

      print('[DEBUG] Thông tin đơn hàng:');
      print('   - User ID: $userId');
      print('   - Số sản phẩm: ${details.length}');
      print('   - Tổng tiền gốc: ${CurrencyFormatter.formatVND(total)}');
      print(
        '   - Tổng tiền sau giảm: ${CurrencyFormatter.formatVND(finalTotal)}',
      );
      print(
        '   - Địa chỉ: ${_selectedAddress!.fullName} - ${_selectedAddress!.addressLine1}',
      );
      print('   - Ghi chú: ${_notesController.text.trim()}');
      print('   - Mã giảm giá code: $_selectedDiscountId');
      print('   - Mã giảm giá UUID: ${_selectedDiscount?['ma_giam_gia']}');

      if (_selectedDiscount != null) {
        print('[DEBUG] Thông tin mã giảm giá:');
        print('   - Code: ${_selectedDiscount!['code']}');
        print('   - Loại: ${_selectedDiscount!['loai_giam_gia']}');
        print('   - Giá trị: ${_selectedDiscount!['muc_giam_gia']}');
        print('   - Đơn tối thiểu: ${_selectedDiscount!['don_gia_toi_thieu']}');

        // Kiểm tra validation mã giảm giá
        final validationError = _validateDiscount(_selectedDiscount!, total);
        if (validationError != null) {
          print('[DEBUG] Mã giảm giá không hợp lệ: $validationError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mã giảm giá không hợp lệ: $validationError'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final discountAmount = _calculateDiscountAmount(total);
        print(
          '[DEBUG] Số tiền được giảm: ${CurrencyFormatter.formatVND(discountAmount)}',
        );
        print(
          '[DEBUG] Tổng tiền sau giảm: ${CurrencyFormatter.formatVND(total - discountAmount)}',
        );
      }

      if (_paymentMethod == 'VNPay') {
        // VNPay: Thanh toán thành công rồi mới tạo đơn hàng
        await _handleVNPayPaymentFlow(
          userId: userId,
          amount: finalTotal,
          details: details,
        );
      } else {
        // COD: Tạo đơn luôn và trừ mã nếu có
        print('[DEBUG] Gọi SupabaseOrderService.createOrder...');
        final orderId = await SupabaseOrderService.createOrder(
          userId: userId,
          diaChiGiaoHang: _buildFullAddress(_selectedAddress!),
          ghiChu:
              _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
          tongGiaTriDonHang: finalTotal,
          maGiamGia: _selectedDiscount?['ma_giam_gia'],
          items:
              details
                  .map(
                    (d) => {
                      'ma_bien_the_san_pham': d.maBienTheSanPham,
                      'so_luong_mua': d.soLuong,
                      'thanh_tien': d.giaTienTaiThoiDiemThem * d.soLuong,
                    },
                  )
                  .toList(),
        );
        print('[DEBUG] Tạo đơn hàng thành công! Order ID: $orderId');
        // Cập nhật usage cho mã giảm giá nếu có
        if (_selectedDiscount != null && _selectedDiscount!['code'] != null) {
          try {
            await SupabaseDiscountService.updateDiscountUsage(
              _selectedDiscount!['code'],
            );
          } catch (e) {
            print('⚠️ [DEBUG] Không thể update discount usage: $e');
          }
        }
        // Xử lý COD
        await _handleCODPayment(userId, cartProvider);
      }
    } catch (e, stackTrace) {
      print('[DEBUG] Lỗi đặt hàng: $e');
      print('[DEBUG] Stack trace: $stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt hàng: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Đặt hàng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          // Lấy danh sách item theo lựa chọn và merge trùng variant trong UI
          final sourceDetails = _getSourceDetails(cart);
          final merged = <int, CartDetail>{};
          for (final d in sourceDetails) {
            final key = d.maBienTheSanPham;
            if (merged.containsKey(key)) {
              final old = merged[key]!;
              merged[key] = CartDetail(
                maChiTietGioHang: old.maChiTietGioHang,
                maGioHang: old.maGioHang,
                maBienTheSanPham: old.maBienTheSanPham,
                soLuong: old.soLuong + d.soLuong,
                giaTienTaiThoiDiemThem: old.giaTienTaiThoiDiemThem,
                productVariant: old.productVariant,
              );
            } else {
              merged[key] = d;
            }
          }
          final items = merged.values.toList();
          final total = items.fold<double>(
            0.0,
            (s, it) => s + it.giaTienTaiThoiDiemThem * it.soLuong,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Địa chỉ giao hàng (theo thiết kế card)
                      const Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAddressCards(),
                      const SizedBox(height: 16),

                      // Phương thức thanh toán (theo thiết kế card)
                      _buildPaymentMethodSectionStyled(),
                      const SizedBox(height: 16),

                      const Text(
                        'Tóm tắt đơn hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map(
                        (d) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product image
                              Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child:
                                      (d
                                                  .productVariant
                                                  ?.product
                                                  ?.hinhAnh
                                                  .isNotEmpty ==
                                              true)
                                          ? CachedNetworkImage(
                                            imageUrl:
                                                d
                                                    .productVariant!
                                                    .product!
                                                    .hinhAnh
                                                    .first,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (context, url) => const Center(
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.image_not_supported,
                                                      size: 24,
                                                      color:
                                                          AppColors.mediumGray,
                                                    ),
                                          )
                                          : const Icon(
                                            Icons.image,
                                            color: AppColors.mediumGray,
                                          ),
                                ),
                              ),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.productVariant?.product?.tenSanPham ??
                                          'Sản phẩm',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Size: ${d.productVariant?.size?.tenSize ?? '-'} · Màu: ${d.productVariant?.color?.tenMau ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'x${d.soLuong}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.formatVND(
                                      d.giaTienTaiThoiDiemThem * d.soLuong,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.priceRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      /*    // Số điện thoại
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Số điện thoại: ${auth.user?.soDienThoai ?? 'Chưa cập nhật'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),*/

                      // Mã giảm giá
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mã giảm giá',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_selectedDiscount != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDiscountId = null;
                                  _selectedDiscount = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bỏ chọn',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showDiscountDialog,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  _selectedDiscount != null
                                      ? AppColors.accentRed
                                      : AppColors.borderLight,
                              width: _selectedDiscount != null ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color:
                                _selectedDiscount != null
                                    ? AppColors.accentRed.withOpacity(0.05)
                                    : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedDiscount != null
                                          ? AppColors.accentRed
                                          : AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_offer,
                                  size: 20,
                                  color:
                                      _selectedDiscount != null
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDiscount != null
                                          ? _selectedDiscount!['noi_dung']
                                          : 'Chọn mã giảm giá',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _selectedDiscount != null
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (_selectedDiscount != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedDiscount!['mo_ta'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color:
                                    _selectedDiscount != null
                                        ? AppColors.accentRed
                                        : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ghi chú
                      const Text(
                        'Ghi chú',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập ghi chú cho đơn hàng (tùy chọn)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Column(
                  children: [
                    // Tổng tiền gốc
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng cộng',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          CurrencyFormatter.formatVND(total),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    // Hiển thị giảm giá nếu có
                    if (_selectedDiscount != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Giảm giá (${_selectedDiscount!['code']})',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '-${CurrencyFormatter.formatVND(_calculateDiscountAmount(total))}',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 8),
                    ],

                    // Tổng tiền sau giảm giá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDiscount != null
                              ? 'Thành tiền'
                              : 'Tổng cộng',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatVND(
                            _calculateTotalAfterDiscount(total),
                          ),
                          style: const TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: _submitting ? 'Đang đặt...' : 'ĐẶT ĐƠN',
                      type: AppButtonType.accent,
                      size: AppButtonSize.large,
                      onPressed: _submitting ? null : _placeOrder,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // legacy method removed; now using _buildPaymentMethodSectionStyled()

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.accentRed.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.accentRed : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentRed : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.accentRed : AppColors.textPrimary,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged:
                  (value) =>
                      setState(() => _paymentMethod = value ?? _paymentMethod),
              activeColor: AppColors.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  // Address cards UI using new address system
  Widget _buildAddressCards() {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, child) {
        if (addressProvider.addresses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  size: 48,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có địa chỉ nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy thêm địa chỉ để thuận tiện cho việc đặt hàng',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  width: 400,
                  text: 'Thêm địa chỉ mới',
                  type: AppButtonType.secondary,
                  onPressed: _addNewAddress,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...addressProvider.addresses.map((address) {
              final isSelected = _selectedAddress?.id == address.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.accentRed.withOpacity(0.08)
                          : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.accentRed
                            : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<UserAddress>(
                      value: address,
                      groupValue: _selectedAddress,
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress = value;
                        });
                      },
                      activeColor: AppColors.accentRed,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  address.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (address.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentRed.withOpacity(
                                      0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Mặc định',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.accentRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _selectAddress(),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            address.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildFullAddress(address),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            AppButton(
              width: 400,
              text: 'Thêm địa chỉ mới',
              type: AppButtonType.secondary,
              onPressed: _addNewAddress,
            ),
          ],
        );
      },
    );
  }

  String _buildFullAddress(UserAddress address) {
    final parts = <String>[
      address.addressLine1,
      if (address.addressLine2 != null) address.addressLine2!,
      if (address.ward != null) address.ward!,
      if (address.district != null) address.district!,
      address.city,
    ];
    return parts.join(', ');
  }

  void _selectAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddressSelectionScreen(
              selectedAddress: _selectedAddress,
              onAddressSelected: (address) {
                setState(() {
                  _selectedAddress = address;
                });
                Navigator.pop(context);
              },
            ),
      ),
    );
  }

  void _addNewAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
    ).then((value) {
      if (value == true) {
        _loadAddresses(); // Refresh addresses after adding
      }
    });
  }

  // Styled payment methods as cards with radio at right
  Widget _buildPaymentMethodSectionStyled() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức thanh toán',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'COD',
          'Thanh toán khi nhận hàng',
          Icons.local_shipping,
          _paymentMethod == 'COD',
          () => setState(() => _paymentMethod = 'COD'),
        ),

        const SizedBox(height: 8),
        _buildPaymentOption(
          'VNPay',
          'Thanh toán qua VNPay',
          Icons.payment,
          _paymentMethod == 'VNPay',
          () => setState(() => _paymentMethod = 'VNPay'),
        ),
      ],
    );
  }

  // New flow: Pay first, then create order on success
  Future<void> _handleVNPayPaymentFlow({
    required int userId,
    required double amount,
    required List<CartDetail> details,
  }) async {
    try {
      print('🔄 [DEBUG] Bắt đầu xử lý thanh toán VNPay (pay-then-create)...');

      // Tạo URL thanh toán VNPay
      final paymentUrl = await VNPayService.createPaymentUrl(
        orderId: DateTime.now().millisecondsSinceEpoch, // temp reference id
        amount: amount,
        orderInfo: 'Thanh toan don hang ',
        returnUrl: 'zamyapp://vnpay-return',
      );

      if (paymentUrl != null) {
        print('✅ [DEBUG] Tạo URL thanh toán VNPay thành công');

        // Hiển thị VNPay payment với WebView
        await VNPayService.showPayment(
          context: context,
          paymentUrl: paymentUrl,
          onPaymentSuccess: (params) async {
            print('✅ [DEBUG] Thanh toán VNPay thành công: $params');
            // Tạo đơn hàng SAU khi thanh toán thành công
            final orderId = await SupabaseOrderService.createOrder(
              userId: userId,
              diaChiGiaoHang: _buildFullAddress(_selectedAddress!),
              ghiChu: 'Đã thanh toán online',
              tongGiaTriDonHang: amount,
              maGiamGia: _selectedDiscount?['ma_giam_gia'],
              items:
                  details
                      .map(
                        (d) => {
                          'ma_bien_the_san_pham': d.maBienTheSanPham,
                          'so_luong_mua': d.soLuong,
                          'thanh_tien': d.giaTienTaiThoiDiemThem * d.soLuong,
                        },
                      )
                      .toList(),
            );
            // Cập nhật usage cho mã giảm giá nếu có
            if (_selectedDiscount != null &&
                _selectedDiscount!['code'] != null) {
              try {
                await SupabaseDiscountService.updateDiscountUsage(
                  _selectedDiscount!['code'],
                );
              } catch (e) {
                print('⚠️ [DEBUG] Không thể update discount usage: $e');
              }
            }
            // Xóa item đã đặt khỏi giỏ
            try {
              final cartProvider = Provider.of<CartProvider>(
                context,
                listen: false,
              );
              final selectedIds = widget.selectedCartDetailIds ?? {};
              print('🔄 [DEBUG] Xóa các item đã đặt: $selectedIds');
              await SupabaseCartService.removeSelectedFromCart(
                userId,
                selectedIds,
              );
              await cartProvider.loadCart();
            } catch (e) {
              print(
                '⚠️ [DEBUG] Không thể xóa/refresh giỏ hàng sau thanh toán: $e',
              );
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thanh toán thành công!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const OrderScreen()),
              (route) => route.isFirst,
            );
          },
          onPaymentError: (params) {
            print('❌ [DEBUG] Thanh toán VNPay thất bại: $params');

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Thanh toán thất bại: ${VNPayService.getPaymentMessage(params)}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      } else {
        print('❌ [DEBUG] Không thể tạo URL thanh toán VNPay');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi tạo URL thanh toán VNPay. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Lỗi thanh toán VNPay: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thanh toán VNPay: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Kiểm tra tồn kho hiện tại cho danh sách item hợp nhất
  Future<bool> _validateStock(List<CartDetail> details) async {
    try {
      final client = SupabaseConfig.client;
      for (final d in details) {
        final variantId = d.maBienTheSanPham;
        final qty = d.soLuong;
        final row =
            await client
                .from('product_variants')
                .select('ton_kho')
                .eq('ma_bien_the', variantId)
                .maybeSingle();
        if (row == null) return false;
        final stock = (row['ton_kho'] as num).toInt();
        if (qty > stock) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleCODPayment(int userId, CartProvider cartProvider) async {
    try {
      print('[DEBUG] Xử lý thanh toán COD...');

      // Remove only selected items
      final selectedIds = widget.selectedCartDetailIds ?? {};
      print('[DEBUG] Xóa các item đã đặt: $selectedIds');
      await SupabaseCartService.removeSelectedFromCart(userId, selectedIds);
      await cartProvider.loadCart();
      print('[DEBUG] Xóa item đã đặt thành công!');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrderScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      print('[DEBUG] Lỗi xử lý COD: $e');
      rethrow;
    }
  }

  Future<void> _loadDiscounts() async {
    print('[DEBUG] Bắt đầu tải mã giảm giá...');
    setState(() {
      _loadingDiscounts = true;
    });

    try {
      print(
        '[DEBUG] Gọi SupabaseDiscountService.getAvailableDiscountsForUser()...',
      );
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.maNguoiDung;
      final discounts =
          userId != null
              ? await SupabaseDiscountService.getAvailableDiscountsForUser(
                userId,
              )
              : await SupabaseDiscountService.getAvailableDiscounts();
      print('[DEBUG] Lấy được ${discounts.length} mã giảm giá:');
      for (var discount in discounts) {
        print('   - ${discount['code']}: ${discount['noi_dung']}');
      }

      setState(() {
        _availableDiscounts = discounts;
        _loadingDiscounts = false;
      });
      print('[DEBUG] Cập nhật UI thành công');
    } catch (e, stackTrace) {
      print('[DEBUG] Lỗi tải mã giảm giá: $e');
      print('[DEBUG] Stack trace: $stackTrace');

      setState(() {
        _loadingDiscounts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải mã giảm giá: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showDiscountDialog() {
    print('[DEBUG] Hiển thị bottom sheet mã giảm giá...');
    print('[DEBUG] Số lượng mã giảm giá: ${_availableDiscounts.length}');
    print('[DEBUG] Đang loading: $_loadingDiscounts');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: AppColors.accentRed,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Chọn mã giảm giá',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child:
                      _loadingDiscounts
                          ? const Center(child: CircularProgressIndicator())
                          : _availableDiscounts.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không có mã giảm giá nào',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _availableDiscounts.length,
                            itemBuilder: (context, index) {
                              final discount = _availableDiscounts[index];
                              final isSelected =
                                  _selectedDiscountId == discount['code'];

                              // Lấy tổng tiền hiện tại để validate
                              final cartProvider = Provider.of<CartProvider>(
                                context,
                                listen: false,
                              );
                              final totalAmount = cartProvider.cartDetails
                                  .fold<double>(
                                    0.0,
                                    (sum, item) =>
                                        sum +
                                        (item.giaTienTaiThoiDiemThem *
                                            item.soLuong),
                                  );

                              final validationError = _validateDiscount(
                                discount,
                                totalAmount,
                              );
                              final canApply = validationError == null;

                              print(
                                '[DEBUG] Hiển thị mã ${index + 1}: ${discount['code']} - ${discount['noi_dung']} - Có thể áp dụng: $canApply',
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.accentRed
                                            : canApply
                                            ? Colors.grey.shade300
                                            : Colors.red.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      isSelected
                                          ? AppColors.accentRed.withOpacity(
                                            0.05,
                                          )
                                          : canApply
                                          ? Colors.white
                                          : Colors.red.shade50,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.accentRed
                                              : canApply
                                              ? Colors.grey.shade200
                                              : Colors.red.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      canApply
                                          ? Icons.local_offer
                                          : Icons.block,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : canApply
                                              ? Colors.grey.shade600
                                              : Colors.red.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    discount['noi_dung'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected
                                              ? AppColors.accentRed
                                              : canApply
                                              ? AppColors.textPrimary
                                              : Colors.red.shade600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        canApply
                                            ? (discount['mo_ta'] ?? '')
                                            : validationError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              canApply
                                                  ? AppColors.textLight
                                                  : Colors.red.shade600,
                                          fontWeight:
                                              canApply
                                                  ? FontWeight.normal
                                                  : FontWeight.w500,
                                        ),
                                      ),
                                      if (canApply) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentRed
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                discount['code'],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.accentRed,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                discount['loai_giam_gia'] ==
                                                        'percentage'
                                                    ? 'Giảm ${discount['muc_giam_gia']}%'
                                                    : 'Giảm ${CurrencyFormatter.formatVND((discount['muc_giam_gia'] as num).toDouble())}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            Icons.check_circle,
                                            color: AppColors.accentRed,
                                            size: 24,
                                          )
                                          : canApply
                                          ? Icon(
                                            Icons.radio_button_unchecked,
                                            color: Colors.grey.shade400,
                                            size: 24,
                                          )
                                          : Icon(
                                            Icons.block,
                                            color: Colors.red.shade400,
                                            size: 24,
                                          ),
                                  onTap:
                                      canApply
                                          ? () {
                                            print(
                                              '[DEBUG] Chọn mã giảm giá: ${discount['code']}',
                                            );
                                            setState(() {
                                              if (isSelected) {
                                                _selectedDiscountId = null;
                                                _selectedDiscount = null;
                                              } else {
                                                _selectedDiscountId =
                                                    discount['code'];
                                                _selectedDiscount = discount;
                                              }
                                            });
                                            Navigator.pop(context);
                                          }
                                          : null,
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }
}
