import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._preferences) {
    _load();
  }
  final SharedPreferences _preferences;
  static const _key = 'ouedna_favorites';
  final Set<int> _favorites = {};
  Set<int> get favorites => Set.unmodifiable(_favorites);
  void _load() {
    final list = _preferences.getStringList(_key);
    if (list != null) {
      _favorites.clear();
      for (final item in list) {
        final id = int.tryParse(item);
        if (id != null) _favorites.add(id);
      }
    }
  }

  bool isFavorite(int placeId) => _favorites.contains(placeId);
  bool contains(int placeId) => isFavorite(placeId);
  Future<void> toggle(int placeId) async {
    if (_favorites.contains(placeId)) {
      _favorites.remove(placeId);
    } else {
      _favorites.add(placeId);
    }
    notifyListeners();
    await _preferences.setStringList(
      _key,
      _favorites.map((e) => e.toString()).toList(),
    );
  }
}
