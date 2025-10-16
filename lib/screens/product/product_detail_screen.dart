import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/size.dart';
import '../../models/color.dart';
import '../../models/review.dart';
import '../../services/supabase_product_service.dart';
import '../../services/supabase_variant_service.dart';
import '../../services/supabase_review_service.dart';
import '../../services/supabase_favorite_service.dart';
import '../../providers/favorites_provider.dart';
import '../../services/supabase_cart_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/rating_stars.dart';
import '../../widgets/review/reviews_list_widget.dart';
import '../order/order_screen.dart';
import '../auth/login_screen.dart';
import '../review/review_screen.dart';
import '../../utils/review_dialog_helper.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/store_location.dart';
import '../../widgets/map/free_store_map.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? product;
  List<ProductVariant> variants = [];
  List<Size> sizes = [];
  List<ColorModel> colors = [];
  List<Review> reviews = [];
  Map<String, dynamic> reviewStats = {};
  bool isLoading = true;
  bool isFavorite = false;
  
  // Selected variants
  int? selectedSizeId;
  int? selectedColorId;
  int quantity = 1;
  
  PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    try {
      setState(() => isLoading = true);
      
      final productData = await SupabaseProductService.getProductById(widget.productId);
      
      if (productData != null) {
        setState(() {
          product = productData;
        });
        
        await _loadVariantsAndOptions();
        await _checkFavoriteStatus();
      }
    } catch (e) {
      print('Error loading product details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadVariantsAndOptions() async {
    if (product == null) return;
    
    try {
      final futures = await Future.wait([
         SupabaseVariantService.getSizesForProduct(product!.maSanPham),
        // SupabaseVariantService.getSizes(),
        //SupabaseVariantService.getColors(),
         SupabaseVariantService.getColorsForProduct(product!.maSanPham),
        SupabaseVariantService.getProductVariants(product!.maSanPham),
        SupabaseReviewService.getProductReviews(product!.maSanPham),
        SupabaseReviewService.getProductReviewStats(product!.maSanPham),
      ]);
      
      setState(() {
        sizes = futures[0] as List<Size>;
        colors = futures[1] as List<ColorModel>;
        variants = futures[2] as List<ProductVariant>;
        reviews = futures[3] as List<Review>;
        reviewStats = futures[4] as Map<String, dynamic>;
      });
    } catch (e) {
      print('Error loading variants: $e');
    }
  }

  Future<void> _checkLoginAndAddToCart() async {
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
  
  // 3. Kiểm tra tồn kho - QUAN TRỌNG
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
    product!, 
    selectedSizeId!, 
    selectedColorId!, 
    quantity
  );
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã thêm vào giỏ hàng' : 'Lỗi khi thêm vào giỏ hàng'),
        backgroundColor: success ? Colors.green : AppColors.accentRed,
      ),
    );
  }
}
  ProductVariant? _getSelectedVariant() {
  if (selectedSizeId == null || selectedColorId == null) {
    return null;
  }
  
  try {
    return variants.firstWhere(
      (variant) => variant.maSize == selectedSizeId && variant.maMau == selectedColorId,
    );
  } catch (e) {
    return null;
  }
}

int _getAvailableStock() {
  final variant = _getSelectedVariant();
  return variant?.tonKho ?? 0;
}
 void _checkLoginAndBuyNow() {
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
  
  // 4. Chuyển đến màn hình đặt hàng
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const OrderScreen(),
    ),
  );
}

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      _showLoginDialog();
      return;
    }
    try {
      final fav = Provider.of<FavoritesProvider>(context, listen: false);
      await fav.toggle(authProvider.user!.maNguoiDung, product!.maSanPham);
      setState(() {
        isFavorite = fav.isFavorite(product!.maSanPham);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavorite ? 'Đã thêm vào danh sách yêu thích' : 'Đã xóa khỏi danh sách yêu thích'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && product != null) {
      try {
        final fav = Provider.of<FavoritesProvider>(context, listen: false);
        await fav.ensureLoaded(authProvider.user!.maNguoiDung);
        setState(() {
          isFavorite = fav.isFavorite(product!.maSanPham);
        });
      } catch (e) {
        print('Error checking favorite status: $e');
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập'),
        content: const Text('Bạn cần đăng nhập để thực hiện chức năng này'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentRed),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        body: const Center(
          child: Text('Không tìm thấy sản phẩm'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final name = product!.tenSanPham;
              final id = product!.maSanPham;
              final url = 'https://zamy.shop/product/$id';
              final text = 'Xem sản phẩm "$name" tại $url';
              Share.share(text, subject: name);
            },
            icon: const Icon(Icons.share, color: Colors.black),
          ),
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.accentRed : Colors.black,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            _buildProductImages(),
            
            // Product Info
            _buildProductInfo(),
            
            // Divider
            Container(
              height: 8,
              color: const Color(0xFFF5F5F5),
            ),
            
            // Product Options
            _buildProductOptions(),
            
            // Divider  
            Container(
              height: 8,
              color: const Color(0xFFF5F5F5),
            ),
            
            // Description
            _buildDescription(),
            
            // Divider
            Container(
              height: 8,
              color: const Color(0xFFF5F5F5),
            ),
            
           /* // Store Location Map
            _buildStoreLocationSection(),*/
            
            // Divider
            Container(
              height: 8,
              color: const Color(0xFFF5F5F5),
            ),
            
            // Reviews
            _buildReviewsSection(),
            
            const SizedBox(height: 80), // Space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductImages() {
    return Container(
      height: 350,
      color: Colors.white,
      child: product!.hinhAnh?.isNotEmpty == true
          ? Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: product!.hinhAnh!.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: product!.hinhAnh![index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.accentRed),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (product!.hinhAnh!.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product!.hinhAnh!.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index 
                                ? AppColors.accentRed 
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Container(
              color: const Color(0xFFF5F5F5),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₫${product!.giaBan.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentRed,
                ),
              ),
              if (product!.mucGiaGoc > product!.giaBan) ...[
                const SizedBox(width: 8),
                Text(
                  '₫${product!.mucGiaGoc.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '-${(((product!.mucGiaGoc - product!.giaBan) / product!.mucGiaGoc) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Product Name
          Text(
            product!.tenSanPham,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Rating
          Row(
            children: [
              RatingStars(
                rating: (reviewStats['averageRating'] ?? 0.0).toDouble(),
                itemSize: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${(reviewStats['averageRating'] ?? 0.0).toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${reviewStats['totalReviews'] ?? 0} đánh giá)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductOptions() {
  final availableStock = _getAvailableStock();
  
  return Container(
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Size Selection
        if (sizes.isNotEmpty) ...[
          const Text(
            'Size',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              final isSelected = selectedSizeId == size.maSize;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedSizeId = size.maSize;
                    // Reset quantity khi đổi size
                    quantity = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentRed : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.accentRed : Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    size.tenSize,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Color Selection
        if (colors.isNotEmpty) ...[
          const Text(
            'Màu sắc',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = selectedColorId == color.maMau;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColorId = color.maMau;
                    // Reset quantity khi đổi màu
                    quantity = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentRed : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.accentRed : Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    color.tenMau,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Stock Info - THÊM MỚI
        if (selectedSizeId != null && selectedColorId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: availableStock > 0 
                  ? Colors.green.shade50 
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  availableStock > 0 ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: availableStock > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  availableStock > 0 
                      ? 'Còn hàng: $availableStock sản phẩm'
                      : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 14,
                    color: availableStock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Quantity - CẬP NHẬT
        Row(
          children: [
            const Text(
              'Số lượng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? () {
                      setState(() {
                        quantity--;
                      });
                    } : null,
                    icon: const Icon(Icons.remove, size: 16),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    // Giới hạn quantity không vượt quá tồn kho
                    onPressed: (availableStock > 0 && quantity < availableStock) ? () {
                      setState(() {
                        quantity++;
                      });
                    } : null,
                    icon: const Icon(Icons.add, size: 16),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildDescription() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả sản phẩm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product!.moTaSanPham ?? 'Chưa có mô tả sản phẩm',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

 /* Widget _buildStoreLocationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vị trí cửa hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Show the first store as default (you can modify this logic)
          FreeStoreMap(
            store: StoreLocation.stores.first,
            height: 200,
            showDirectionsButton: true,
          ),
          const SizedBox(height: 12),
          // Store list
          ...StoreLocation.stores.map((store) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        store.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Giờ mở cửa: ${store.hours}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.directions),
                  onPressed: () => _openGoogleMaps(store),
                  tooltip: 'Chỉ đường',
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(StoreLocation store) async {
    final lat = store.latitude;
    final lng = store.longitude;
    
    // Mở Google Maps web trực tiếp
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở Google Maps. Vui lòng kiểm tra kết nối internet.'),
          ),
        );
      }
    }
  }*/

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: ReviewsListWidget(
        productId: product!.maSanPham,
        onReply: (review) => showReplyDialog(context, review),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

 Widget _buildBottomBar() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _checkLoginAndAddToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE4D2D),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Thêm vào giỏ hàng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}