import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/supabase_product_service.dart';
import '../../services/supabase_review_service.dart';
import '../../services/supabase_favorite_service.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/common/search_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_search_service.dart';
import '../../widgets/common/filter_chip.dart';
import '../notifications/notifications_screen.dart';
import 'product_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/product/product_options_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/ai_chat/bubble_visibility.dart';
import '../../services/supabase_variant_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> _categories = [];
  List<Product> _filteredProducts = [];
  Map<int, Map<String, num>> _productRatings = {}; // productId -> {avg,count}
  Set<int> _favoriteProductIds = {};
  String _selectedCategory = 'Tất cả';
  String _sortBy = 'Mới nhất';
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Show chat bubble on Products screen
    BubbleVisibility.show();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load categories first
      final categories = await SupabaseProductService.getCategories();
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      
      // Load initial products
      _filterProducts();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _filterProducts() async {
    try {
      setState(() => _isLoading = true);
      
      // Get category ID if not "Tất cả"
      String? categoryId;
      if (_selectedCategory != 'Tất cả') {
        final category = _categories.firstWhere(
          (cat) => cat.tenDanhMuc == _selectedCategory,
          orElse: () => Category(maDanhMuc: 0, tenDanhMuc: '', createdAt: DateTime.now()),
        );
        categoryId = category.maDanhMuc.toString();
      }
      
      // Map sort options
      String? sortBy;
      switch (_sortBy) {
        case 'Giá thấp đến cao':
          sortBy = 'price_asc';
          break;
        case 'Giá cao đến thấp':
          sortBy = 'price_desc';
          break;
        case 'Tên A-Z':
          sortBy = 'name_asc';
          break;
        default:
          sortBy = null; // Default sort by creation date
      }
      
      // Fetch filtered products
      final products = await SupabaseProductService.getProducts(
        categoryId: categoryId != null ? int.parse(categoryId) : null,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: sortBy,
      );
      
      // Load ratings for all products
      final ratingsEntries = await Future.wait(products.map((p) async {
        final stats = await SupabaseReviewService.getProductReviewStats(p.maSanPham);
        return MapEntry(p.maSanPham, {
          'avg': (stats['averageRating'] ?? 0.0) as num,
          'count': (stats['totalReviews'] ?? 0) as num,
        });
      }));
      final productRatings = {for (final e in ratingsEntries) e.key: e.value};
      
      // Sync favorites via provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await Provider.of<FavoritesProvider>(context, listen: false)
            .ensureLoaded(authProvider.user!.maNguoiDung);
      }
      
      setState(() {
        _filteredProducts = products;
        _productRatings = productRatings;
        if (authProvider.user != null) {
          _favoriteProductIds = Provider.of<FavoritesProvider>(context, listen: false)
              .favoriteIds;
        } else {
          _favoriteProductIds = {};
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lọc sản phẩm: $e')),
        );
      }
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
          'Sản phẩm',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // removed notification icon on product screen per request
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Tìm kiếm sản phẩm...',
              onChanged: (value) => _filterProducts(),
              onPickImage: _onPickSearchImage,
            ),
          ),

          // Filter and Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final small = screenWidth < 360;
                      final itemTextStyle = TextStyle(
                        fontSize: small ? 12 : 14,
                        color: AppColors.textPrimary,
                      );
                      return DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        isDense: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        selectedItemBuilder: (context) {
                          final items = ['Tất cả', ..._categories.map((c) => c.tenDanhMuc)];
                          return items.map((value) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                value == 'Tất cả' ? 'Tất cả danh mục' : value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: itemTextStyle,
                              ),
                            );
                          }).toList();
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'Tất cả',
                            child: Text(
                              'Tất cả danh mục',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: itemTextStyle,
                            ),
                          ),
                          ..._categories.map((category) => DropdownMenuItem(
                                value: category.tenDanhMuc,
                                child: Text(
                                  category.tenDanhMuc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: itemTextStyle,
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                          _filterProducts();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Sort Button
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final small = screenWidth < 360;
                    final labelStyle = TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: small ? 12 : 14,
                    );
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (value) {
                          setState(() => _sortBy = value);
                          _filterProducts();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _sortBy,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: labelStyle,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'Mới nhất', child: Text('Mới nhất')),
                          PopupMenuItem(value: 'Giá thấp đến cao', child: Text('Giá thấp đến cao')),
                          PopupMenuItem(value: 'Giá cao đến thấp', child: Text('Giá cao đến thấp')),
                          PopupMenuItem(value: 'Tên A-Z', child: Text('Tên A-Z')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy sản phẩm',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hãy thử từ khóa khác hoặc chọn danh mục khác',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 350, // Chiều cao cố định cho mỗi card
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return Consumer<FavoritesProvider>(
                            builder: (context, favoritesProvider, _) {
                              return ProductCard(
                                product: product,
                                rating: (_productRatings[product.maSanPham]?['avg'] ?? 0.0).toDouble(),
                                reviewCount: (_productRatings[product.maSanPham]?['count'] ?? 0).toInt(),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(productId: product.maSanPham),
                                  ),
                                ),
                                onFavorite: () => _toggleFavorite(product.maSanPham),
                                onAddToCart: () => _showProductOptionsBottomSheet(product),
                                isFavorite: favoritesProvider.isFavorite(product.maSanPham),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(int productId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng tính năng yêu thích')),
        );
        return;
      }
      final fav = Provider.of<FavoritesProvider>(context, listen: false);
      await fav.toggle(authProvider.user!.maNguoiDung, productId);
      setState(() {
        _favoriteProductIds = fav.favoriteIds;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _showProductOptionsBottomSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductOptionsBottomSheet(
        product: product,
        
        onAddedToCart: () {
          // Optionally refresh data or show success message
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onPickSearchImage() async {
    try {
      // Hỏi người dùng chọn nguồn ảnh: camera hay thư viện
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp từ camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      setState(() => _isLoading = true);
      final resp = await AISearchService.searchByImage(
        message: _searchController.text.trim(),
        image: image,
      );

      final products = (resp['products'] as List<dynamic>? ?? []);
      final mapped = products.map<Product>((p) {
        return Product(
          maSanPham: p['id'] is int ? p['id'] : int.parse(p['id'].toString()),
          tenSanPham: p['name'] ?? '',
          moTaSanPham: p['description'],
          mucGiaGoc: (p['original_price'] ?? 0).toDouble(),
          giaBan: (p['price'] ?? 0).toDouble(),
          soLuongDatToiThieu: 1,
          trangThaiHienThi: true,
          ngayTaoBanGhi: DateTime.now(),
          ngaySuaBanGhi: null,
          maDanhMuc: 0,
          maBoSuuTap: null,
          maGiamGia: null,
          hinhAnh: List<String>.from(p['images'] ?? const []),
        );
      }).toList();

      setState(() {
        _filteredProducts = mapped;
        _isLoading = false;
      });
    } catch (e, st) {
      // Print logs to console only
      // ignore: avoid_print
      print('[AI-SEARCH][ERROR] $e');
      // ignore: avoid_print
      print(st);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy kết quả phù hợp. Hãy thử ảnh/ từ khóa khác.')),
        );
      }
    }
  }
}
