import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/common/collection_card.dart';
import '../../models/product.dart';
import '../../models/banner_model.dart';
import '../../models/collection.dart';
import '../../services/supabase_product_service.dart';
import '../../services/supabase_review_service.dart';
import '../../services/supabase_banner_service.dart';
import '../../services/supabase_collection_service.dart';
import '../../services/supabase_favorite_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/ai_chat/bubble_visibility.dart';
import 'package:provider/provider.dart';
import '../product/product_detail_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../product/products_screen.dart';
import '../notifications/notifications_screen.dart';
import '../collections/collections_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> featuredProducts = [];
  Map<int, Map<String, num>> productRatings = {}; // productId -> {avg,count}
  List<BannerModel> banners = [];
  List<Collection> collections = [];
  Set<int> favoriteProductIds = {};
  bool isLoading = true;
  int? _notifUserIdLoaded;

  @override
  void initState() {
    super.initState();
    // Ensure chat bubble is visible on Home
    BubbleVisibility.show();
    _loadData();
    // Ensure notifications are loaded after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _maybeLoadNotifications(auth);
      auth.addListener(() {
        _maybeLoadNotifications(auth);
      });
    });
  }

  void _maybeLoadNotifications(AuthProvider auth) {
    if (auth.user == null) return;
    final userId = auth.user!.maNguoiDung;
    if (_notifUserIdLoaded == userId) return;
    _notifUserIdLoaded = userId;
    Provider.of<NotificationProvider>(context, listen: false)
        .loadNotifications(userId);
  }

  Future<void> _loadData() async {
    try {
      print('🔄 Starting to load data...');
      
      // Load products, banners và collections song song
      final futures = await Future.wait([
        SupabaseProductService.getProducts(limit: 8),
        SupabaseBannerService.getBanners(),
        SupabaseCollectionService.getCollections(),
      ]);
      
      final products = futures[0] as List<Product>;
      final banners = futures[1] as List<BannerModel>;
      final collections = futures[2] as List<Collection>;
      
      print('📦 Products loaded: ${products.length}');
      if (products.isNotEmpty) {
        print('Sample product: ${products.first.tenSanPham}');
        print('Product images: ${products.first.hinhAnh}');
      }
      
      print('🖼️ Banners loaded: ${banners.length}');
      if (banners.isNotEmpty) {
        print('Sample banner: ${banners.first.maBanner}');
        print('Banner image: ${banners.first.hinhAnh}');
      }
      
      print('📚 Collections loaded: ${collections.length}');
      if (collections.isNotEmpty) {
        print('Sample collection: ${collections.first.tenBoSuuTap}');
      }
      
      // Load favorite products via provider for global sync
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await Provider.of<FavoritesProvider>(context, listen: false)
            .ensureLoaded(authProvider.user!.maNguoiDung);
      }
      
      // fetch rating stats per product in parallel
      final ratingsEntries = await Future.wait(products.map((p) async {
        final stats = await SupabaseReviewService.getProductReviewStats(p.maSanPham);
        return MapEntry(p.maSanPham, {
          'avg': (stats['averageRating'] ?? 0.0) as num,
          'count': (stats['totalReviews'] ?? 0) as num,
        });
      }));
      productRatings = {for (final e in ratingsEntries) e.key: e.value};

      setState(() {
        featuredProducts = products;
        this.banners = banners;
        this.collections = collections;
        if (authProvider.user != null) {
          favoriteProductIds = Provider.of<FavoritesProvider>(context, listen: false)
              .favoriteIds;
        } else {
          favoriteProductIds = {};
        }
        isLoading = false;
      });
      
      print('✅ Data loaded successfully!');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        isLoading = false;
      });
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
          'ZAMY',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Consumer2<AuthProvider, NotificationProvider>(
            builder: (context, auth, notif, _) {
              final unread = notif.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined, 
                        color: AppColors.accentRed,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: unread > 0 ? Colors.red : AppColors.border,
                        shape: BoxShape.rectangle,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: unread > 0 ? Colors.white : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? _buildLoadingState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Banner carousel
                        _buildBannerCarousel(),
                        const SizedBox(height: 32),
                        // Featured products
                        _buildFeaturedProducts(),
                        const SizedBox(height: 32),
                        // Collections
                        _buildCollections(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          // AI Chat Button - chỉ hiển thị ở home
          Positioned(
            right: 16,
            bottom: 16, // Sát dưới một chút
            child: FloatingActionButton(
              heroTag: 'ai_chat_home',
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIChatScreen(),
                  ),
                );
              },
              child: const Icon(Icons.smart_toy, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner loading
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lightGray.withOpacity(0.3),
                  AppColors.lightGray.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accentRed),
            ),
          ),
          const SizedBox(height: 32),
          // Products loading
          _buildProductsLoading(),
          const SizedBox(height: 32),
          // Collections loading
          _buildCollectionsLoading(),
        ],
      ),
    );
  }

  Widget _buildProductsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'SẢN PHẨM NỔI BẬT',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.accentRed),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'BỘ SƯU TẬP',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.accentRed),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel() {
    if (banners.isEmpty) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentRed.withOpacity(0.1),
              AppColors.accentRed.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentRed.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 50,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12),
              Text(
                'Chưa có banner nào',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 220,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        viewportFraction: 1.0,
        enableInfiniteScroll: true,
        enlargeCenterPage: false,
      ),
      items: banners.map((banner) => 
        _buildBannerItem(banner.hinhAnh)
      ).toList(),
    );
  }

  Widget _buildBannerItem(String imageUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lightGray.withOpacity(0.3),
                  AppColors.lightGray.withOpacity(0.1),
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentRed,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentRed.withOpacity(0.1),
                  AppColors.accentRed.withOpacity(0.05),
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Không thể tải hình ảnh',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildFeaturedProducts() {
  if (featuredProducts.isEmpty) {
    return _buildEmptyProducts();
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SẢN PHẨM NỔI BẬT',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProductsScreen(),
              ),
            ),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
       SizedBox(
         height: 300, // Height phù hợp với ProductCard mới
         child: ListView.builder(
           scrollDirection: Axis.horizontal,
           padding: const EdgeInsets.symmetric(horizontal: 16),
           itemCount: featuredProducts.length,
           itemBuilder: (context, index) {
             final product = featuredProducts[index];
             return Padding(
               padding: const EdgeInsets.only(right: 16),
                child: Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, _) {
                    return ProductCard(
                      product: product,
                      width: 180, // Width nhỏ hơn cho giao diện đẹp hơn
                      rating: (productRatings[product.maSanPham]?['avg'] ?? 0.0).toDouble(),
                      reviewCount: (productRatings[product.maSanPham]?['count'] ?? 0).toInt(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(productId: product.maSanPham),
                        ),
                      ),
                      onFavorite: () => _toggleFavorite(product.maSanPham),
                      isFavorite: favoritesProvider.isFavorite(product.maSanPham),
                    );
                  },
                ),
             );
           },
         ),
       ),
    ],
  );
}

  Widget _buildEmptyProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'SẢN PHẨM NỔI BẬT',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lightGray.withOpacity(0.3),
                AppColors.lightGray.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Chưa có sản phẩm nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sản phẩm sẽ được cập nhật sớm',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

 Widget _buildCollections() {
  if (collections.isEmpty) {
    return _buildEmptyCollections();
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BỘ SƯU TẬP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CollectionsScreen(),
                  ),
                ),
                child: const Text(
                  'Xem thêm',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 240, // Tăng height để chứa nội dung
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CollectionCard(
                collection: collection,
                width: 280, // Đặt width cố định
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CollectionsScreen(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildEmptyCollections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'BỘ SƯU TẬP',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentRed.withOpacity(0.1),
                AppColors.accentRed.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentRed.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.collections_outlined,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Chưa có bộ sưu tập nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bộ sưu tập sẽ được cập nhật sớm',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        favoriteProductIds = fav.favoriteIds;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

}