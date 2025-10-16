import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/size.dart';
import '../../models/color.dart';
import '../../services/supabase_variant_service.dart';
import '../../services/supabase_cart_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../../screens/auth/login_screen.dart';

class ProductOptionsBottomSheet extends StatefulWidget {
  final Product product;
  final VoidCallback? onAddedToCart;

  const ProductOptionsBottomSheet({
    super.key,
    required this.product,
    this.onAddedToCart,
  });

  @override
  State<ProductOptionsBottomSheet> createState() =>
      _ProductOptionsBottomSheetState();
}

class _ProductOptionsBottomSheetState extends State<ProductOptionsBottomSheet> {
  List<Size> sizes = [];
  List<ColorModel> colors = [];
  List<ProductVariant> variants = [];
  bool isLoading = true;

  // Selected variants
  int? selectedSizeId;
  int? selectedColorId;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadVariantsAndOptions();
  }

  Future<void> _loadVariantsAndOptions() async {
    try {
      final futures = await Future.wait([
        //SupabaseVariantService.getSizes(),
        SupabaseVariantService.getSizesForProduct(widget.product.maSanPham),
        //  SupabaseVariantService.getColors(),
        SupabaseVariantService.getColorsForProduct(widget.product.maSanPham),
        SupabaseVariantService.getProductVariants(widget.product.maSanPham),
      ]);

      setState(() {
        sizes = futures[0] as List<Size>;
        colors = futures[1] as List<ColorModel>;
        variants = futures[2] as List<ProductVariant>;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading variants: $e');
      setState(() => isLoading = false);
    }
  }

  // Lấy variant đã chọn
  ProductVariant? _getSelectedVariant() {
    if (selectedSizeId == null || selectedColorId == null) {
      return null;
    }

    try {
      return variants.firstWhere(
        (variant) =>
            variant.maSize == selectedSizeId &&
            variant.maMau == selectedColorId,
      );
    } catch (e) {
      return null;
    }
  }

  // Lấy số lượng tồn kho
  int _getAvailableStock() {
    final variant = _getSelectedVariant();
    return variant?.tonKho ?? 0;
  }

  Future<void> _addToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Kiểm tra đăng nhập
    if (authProvider.user == null) {
      _showLoginDialog();
      return;
    }

    // 2. Kiểm tra đã chọn size và màu
    if (selectedSizeId == null || selectedColorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn size và màu sắc'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    // 3. Kiểm tra tồn kho
    final selectedVariant = _getSelectedVariant();

    if (selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy sản phẩm với size và màu đã chọn'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (selectedVariant.tonKho <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm này hiện đã hết hàng'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (quantity > selectedVariant.tonKho) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ còn ${selectedVariant.tonKho} sản phẩm trong kho'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    // 4. Thêm vào giỏ hàng
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final success = await cartProvider.addToCart(
      widget.product,
      selectedSizeId!,
      selectedColorId!,
      quantity,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close bottom sheet
      final errorMessage = cartProvider.lastErrorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã thêm vào giỏ hàng'
                : (errorMessage != null
                    ? _humanizeError(errorMessage)
                    : 'Lỗi khi thêm vào giỏ hàng'),
          ),
          backgroundColor: success ? Colors.green : AppColors.accentRed,
        ),
      );
      widget.onAddedToCart?.call();
    }
  }

  String _humanizeError(String raw) {
    // Strip generic Exception prefix if present
    final cleaned = raw.replaceFirst(RegExp(r'^Exception: '), '');
    // Known messages from service
    if (cleaned.contains('tối đa theo tồn kho') ||
        cleaned.contains('vượt quá tồn kho')) {
      return cleaned;
    }
    return 'Lỗi khi thêm vào giỏ hàng: $cleaned';
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Đăng nhập'),
            content: const Text('Bạn cần đăng nhập để thực hiện chức năng này'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // close bottom sheet
                  // Navigate to login screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableStock = _getAvailableStock();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.tenSanPham,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₫${widget.product.giaBan.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.accentRed),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Size Selection
                    if (sizes.isNotEmpty) ...[
                      const Text(
                        'Size',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            sizes.map((size) {
                              final isSelected = selectedSizeId == size.maSize;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedSizeId = size.maSize;
                                    quantity = 1; // Reset quantity khi đổi size
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.accentRed
                                            : Colors.white,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColors.accentRed
                                              : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    size.tenSize,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Color Selection
                    if (colors.isNotEmpty) ...[
                      const Text(
                        'Màu sắc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            colors.map((color) {
                              final isSelected = selectedColorId == color.maMau;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColorId = color.maMau;
                                    quantity = 1; // Reset quantity khi đổi màu
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.accentRed
                                            : Colors.white,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColors.accentRed
                                              : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    color.tenMau,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Stock Info - THÊM MỚI
                    if (selectedSizeId != null && selectedColorId != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              availableStock > 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                availableStock > 0
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              availableStock > 0
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 18,
                              color:
                                  availableStock > 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              availableStock > 0
                                  ? 'Còn hàng: $availableStock sản phẩm'
                                  : 'Hết hàng',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    availableStock > 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quantity - CẬP NHẬT
                    Row(
                      children: [
                        const Text(
                          'Số lượng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed:
                                    quantity > 1
                                        ? () {
                                          setState(() {
                                            quantity--;
                                          });
                                        }
                                        : null,
                                icon: const Icon(Icons.remove, size: 18),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                              Container(
                                width: 50,
                                alignment: Alignment.center,
                                child: Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                // Giới hạn quantity không vượt quá tồn kho
                                onPressed:
                                    (availableStock > 0 &&
                                            quantity < availableStock)
                                        ? () {
                                          setState(() {
                                            quantity++;
                                          });
                                        }
                                        : null,
                                icon: const Icon(Icons.add, size: 18),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
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
            ),

          const Divider(height: 1),

          // Add to Cart Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (isLoading || availableStock <= 0) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLoading
                      ? 'Đang tải...'
                      : (selectedSizeId != null &&
                          selectedColorId != null &&
                          availableStock <= 0)
                      ? 'Hết hàng'
                      : 'Thêm vào giỏ hàng',
                  style: TextStyle(
                    color:
                        (isLoading || availableStock <= 0)
                            ? Colors.grey.shade600
                            : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
