import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._preferences) {
    _ids = _preferences
            .getStringList(_key)
            ?.map(int.tryParse)
            .whereType<int>()
            .toSet() ??
        <int>{};
  }

  final SharedPreferences _preferences;
  static const _key = 'souf360.favorite_place_ids.v1';
  late Set<int> _ids;

  Set<int> get ids => Set.unmodifiable(_ids);

  bool contains(int placeId) => _ids.contains(placeId);

  Future<void> toggle(int placeId) async {
    if (_ids.contains(placeId)) {
      _ids = {..._ids}..remove(placeId);
    } else {
      _ids = {..._ids, placeId};
    }
    await _preferences.setStringList(
      _key,
      _ids.map((id) => '$id').toList(growable: false),
    );
    notifyListeners();
  }
}
