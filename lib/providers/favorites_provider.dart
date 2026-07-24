import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Favorites are stored purely on-device (a list of post IDs) since the app
/// has no login/account system. Uninstalling the app clears them.
class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Set<String> get favoriteIds => _favoriteIds;

  FavoritesProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(AppConstants.prefFavorites) ?? [];
    _favoriteIds.addAll(saved);
    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(String postId) => _favoriteIds.contains(postId);

  Future<void> toggle(String postId) async {
    if (_favoriteIds.contains(postId)) {
      _favoriteIds.remove(postId);
    } else {
      _favoriteIds.add(postId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.prefFavorites, _favoriteIds.toList());
  }
}
