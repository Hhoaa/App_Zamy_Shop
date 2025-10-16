import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/navigation/bottom_sheet_navigation.dart';
import '../home/home_screen.dart';
import '../product/products_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../../navigation/home_tabs.dart';
import '../../navigation/route_observer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  int _currentIndex = 0;

      final List<Widget> _screens = [
        const HomeScreen(),
        const ProductsScreen(),
        const CartScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 0) {
          // Nếu đang ở tab khác, quay về Home
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomSheetNavigation(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Sync initial tab with global notifier (in case it was set elsewhere)
    _currentIndex = HomeTabs.selectedIndex.value;
    HomeTabs.selectedIndex.addListener(_handleExternalTabChange);

    // If another screen requested a tab change before we reached root, apply it now
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = HomeTabs.consumePendingIndex();
      if (pending != null && pending != _currentIndex) {
        debugPrint('[MainScreen] apply pending tab -> $pending');
        setState(() {
          _currentIndex = pending;
        });
      }
    });
  }

  @override
  void dispose() {
    HomeTabs.selectedIndex.removeListener(_handleExternalTabChange);
    // Unsubscribe route observer
    AppRouteObserver.observer.unsubscribe(this);
    super.dispose();
  }

  void _handleExternalTabChange() {
    final next = HomeTabs.selectedIndex.value;
    if (next == _currentIndex) {
      debugPrint('[MainScreen] external tab change ignored (same): $next');
      return;
    }
    debugPrint('[MainScreen] external tab change -> $next (from: $_currentIndex)');
    setState(() {
      _currentIndex = next;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe route observer
    AppRouteObserver.observer.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // Called when another route above is popped and this one shows again
    final pending = HomeTabs.consumePendingIndex();
    if (pending != null && pending != _currentIndex) {
      debugPrint('[MainScreen] didPopNext apply pending tab -> $pending');
      setState(() {
        _currentIndex = pending;
      });
    }
  }
}
