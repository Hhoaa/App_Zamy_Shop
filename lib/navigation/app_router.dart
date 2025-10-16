import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main/main_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/products_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/news/news_screen.dart';
import '../screens/collections/collections_screen.dart';
import '../screens/store/store_screen.dart';
import '../screens/order/order_screen.dart';
import '../screens/policy/shipping_policy_screen.dart';
import '../screens/policy/size_guide_screen.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
        refreshListenable: SupabaseAuthService.authStateChanges,
        initialLocation: '/home',
        // Chặn các deeplink có scheme lạ (ví dụ: io.supabase.zamyshop://...)
        redirect: (context, state) {
          final scheme = state.uri.scheme;
          if (scheme.isNotEmpty && scheme != 'http' && scheme != 'https') {
            // Supabase đã xử lý session qua deeplink; điều hướng về home
            return '/home';
          }
          // Tự động chuyển vào app nếu đã signed in mà còn ở trang login/register
          final session = Supabase.instance.client.auth.currentSession;
          final location = state.uri.path;
          final isAuthScreen = location == '/login' || location == '/register' || location == '/login-callback';
          if (session != null && isAuthScreen) {
            return '/home';
          }
          // Nếu đã đăng nhập mà vẫn ở root '/', đẩy về home
          if (session != null && (location == '/' || location.isEmpty)) {
            return '/home';
          }
          // Khi signedOut, nếu đang ở trang tài khoản hoặc các trang riêng tư, có thể đưa về home
          if (session == null && location == '/login-callback') {
            return '/home';
          }
          // Nếu đã có user trong AuthProvider thì cũng coi như đăng nhập (phòng khi session chưa attach kịp)
          // Bỏ nếu không cần.
          return null;
        },
    routes: [
      // Optional: route bắt /login-callback nếu nền tảng biến đổi uri → path
      GoRoute(
        path: '/login-callback',
        builder: (context, state) => const MainScreen(),
      ),
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      
      // Product routes
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: productId);
        },
      ),
      
      // Shopping routes
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/order',
        builder: (context, state) => const OrderScreen(),
      ),
      
      // Content routes
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsScreen(),
      ),
      GoRoute(
        path: '/collections',
        builder: (context, state) => const CollectionsScreen(),
      ),
      GoRoute(
        path: '/store',
        builder: (context, state) => const StoreScreen(),
      ),
      
      // Communication routes
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      
      // Policy routes
      GoRoute(
        path: '/shipping-policy',
        builder: (context, state) => const ShippingPolicyScreen(),
      ),
      GoRoute(
        path: '/size-guide',
        builder: (context, state) => const SizeGuideScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Trang không tồn tại',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Đường dẫn: ${state.uri}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
}
