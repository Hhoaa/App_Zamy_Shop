import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
// import 'navigation/app_router.dart'; // Removed GoRouter
import 'screens/main/main_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/address_provider.dart';
import 'config/supabase_config.dart';
import 'services/supabase_auth_service.dart';
import 'navigation/navigator_key.dart';
import 'navigation/route_observer.dart';
import 'services/local_notification_service.dart';
import 'services/auth_deeplink_handler.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase
    await SupabaseConfig.initialize();
    // Initialize local notifications and request permissions early
    await LocalNotificationService.initialize();
    // Gắn listener debug auth state
    SupabaseAuthService.attachAuthDebugListener();
    // Lắng nghe deep link sự kiện passwordRecovery → mở form đặt mật khẩu
    AuthDeepLinkHandler.initialize();

    // Tune image cache to reduce memory spikes during fast scrolling
    PaintingBinding.instance.imageCache.maximumSize = 500; // number of images
    PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024; // 256MB

    // Global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.current);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      // ignore: avoid_print
      print('[CRASH][PlatformDispatcher] $error');
      // ignore: avoid_print
      print(stack);
      return true; // prevent default crash
    };

    runApp(const ZamyShopApp());
  }, (error, stack) {
    // Central place to log crashes
    // ignore: avoid_print
    print('[CRASH] Uncaught error: $error');
    // ignore: avoid_print
    print(stack);
  });
}

class ZamyShopApp extends StatelessWidget {
  const ZamyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkCurrentUser()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: MaterialApp(
        title: 'Zamy Shop',
        theme: AppTheme.lightTheme,
        // Use Navigator-based routing instead of GoRouter
        home: const MainScreen(),
        navigatorKey: AppNavigator.key,
        navigatorObservers: [AppRouteObserver.observer],
        debugShowCheckedModeBanner: false,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          // smoother scrolling to reduce jank
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
          physics: const BouncingScrollPhysics(),
        ),
        builder: (context, child) {
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}