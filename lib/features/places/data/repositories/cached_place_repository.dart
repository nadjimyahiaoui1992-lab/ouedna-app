import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/place.dart';
import '../../domain/entities/place_gallery_image.dart';
import '../../domain/entities/place_page.dart';
import '../../domain/repositories/place_repository.dart';
import '../models/place_model.dart';

class CachedPlaceRepository
    implements PlaceRepository, OfflineAwarePlaceRepository {
  CachedPlaceRepository({
    required PlaceRepository remote,
    required SharedPreferences preferences,
  })  : _remote = remote,
        _preferences = preferences;

  final PlaceRepository _remote;
  final SharedPreferences _preferences;

  static const _placesCacheKey = 'souf360.cached_places.v1';
  bool _isUsingCachedData = false;

  @override
  bool get isUsingCachedData => _isUsingCachedData;

  @override
  Future<PlacePage> getPublishedPlacesPage({
    String? query,
    String? category,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final page = await _remote.getPublishedPlacesPage(
        query: query,
        category: category,
        offset: offset,
        limit: limit,
      );
      if (_isDefaultRequest(query: query, category: category, offset: offset)) {
        await _writeCache(page.places);
      }
      _isUsingCachedData = false;
      return page;
    } catch (_) {
      final cached = _readCache();
      if (cached.isEmpty) rethrow;
      _isUsingCachedData = true;
      final filtered = _filterCached(cached, query: query, category: category);
      final end = (offset + limit).clamp(0, filtered.length);
      return PlacePage(
        places: filtered.sublist(offset.clamp(0, filtered.length), end),
        offset: offset,
        limit: limit,
      );
    }
  }

  @override
  Future<List<Place>> getPublishedPlaces({String? query}) async {
    final page = await getPublishedPlacesPage(query: query, limit: 100);
    return page.places;
  }

  @override
  Future<List<String>> getPublishedCategories() async {
    try {
      return await _remote.getPublishedCategories();
    } catch (_) {
      return _readCache().map((place) => place.category).toSet().toList()
        ..sort();
    }
  }

  @override
  Future<List<PlaceGalleryImage>> getPlaceGallery(int placeId) =>
      _remote.getPlaceGallery(placeId);

  @override
  Stream<void> watchPublishedPlaces() => _remote.watchPublishedPlaces();

  bool _isDefaultRequest(
          {String? query, String? category, required int offset}) =>
      (query == null || query.trim().isEmpty) &&
      (category == null || category.trim().isEmpty) &&
      offset == 0;

  Future<void> _writeCache(List<Place> places) {
    final payload = places
        .map((place) =>
            place is PlaceModel ? place.toJson() : <String, dynamic>{})
        .where((place) => place.isNotEmpty)
        .toList(growable: false);
    return _preferences.setString(_placesCacheKey, jsonEncode(payload));
  }

  List<Place> _readCache() {
    final raw = _preferences.getString(_placesCacheKey);
    if (raw == null) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed
          .whereType<Map<String, dynamic>>()
          .map(PlaceModel.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<Place> _filterCached(
    List<Place> places, {
    String? query,
    String? category,
  }) {
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final normalizedCategory = category?.trim() ?? '';
    return places.where((place) {
      final matchesCategory =
          normalizedCategory.isEmpty || place.category == normalizedCategory;
      final matchesQuery = normalizedQuery.isEmpty ||
          '${place.name} ${place.description} ${place.category} ${place.locationLabel}'
              .toLowerCase()
              .contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList(growable: false);
  }
}
