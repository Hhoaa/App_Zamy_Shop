import 'package:flutter/foundation.dart';
import '../services/supabase_favorite_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<int> _favoriteProductIds = <int>{};
  int? _loadedForUserId;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool isFavorite(int productId) => _favoriteProductIds.contains(productId);
  Set<int> get favoriteIds => Set.unmodifiable(_favoriteProductIds);

  Future<void> ensureLoaded(int userId) async {
    if (_loadedForUserId == userId && _favoriteProductIds.isNotEmpty) return;
    await loadFavorites(userId);
  }

  Future<void> loadFavorites(int userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      final products = await SupabaseFavoriteService.getFavoriteProducts(userId);
      _favoriteProductIds
        ..clear()
        ..addAll(products.map((p) => p.maSanPham));
      _loadedForUserId = userId;
    } catch (_) {
      // ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(int userId, int productId) async {
    final ok = await SupabaseFavoriteService.addToFavorites(userId, productId);
    if (ok) {
      _favoriteProductIds.add(productId);
      notifyListeners();
    }
  }

  Future<void> remove(int userId, int productId) async {
    final ok = await SupabaseFavoriteService.removeFromFavorites(userId, productId);
    if (ok) {
      _favoriteProductIds.remove(productId);
      notifyListeners();
    }
  }

  Future<void> toggle(int userId, int productId) async {
    if (isFavorite(productId)) {
      await remove(userId, productId);
    } else {
      await add(userId, productId);
    }
  }
}


