import '../entities/place.dart';
import 'dart:typed_data';

import '../entities/place_gallery_image.dart';
import '../entities/place_page.dart';

/// Exposes whether the most recent catalogue request was served from the
/// on-device cache because Souf360 could not be reached.
abstract interface class OfflineAwarePlaceRepository {
  bool get isUsingCachedData;
}

/// Allows an on-device copy of published place metadata for no-network browsing.
/// Map tiles are intentionally not downloaded from public tile servers.
abstract interface class OfflineCatalogueRepository {
  Future<int> downloadPublishedCatalogue();
}

abstract interface class PlaceRepository {
  Future<PlacePage> getPublishedPlacesPage({
    String? query,
    String? category,
    int offset = 0,
    int limit = 20,
  });

  Future<List<Place>> getPublishedPlaces({String? query});

  /// Loads exactly one public place for a shared deep link.
  Future<Place?> getPublishedPlaceById(int placeId);

  Future<List<String>> getPublishedCategories();

  Future<List<PlaceGalleryImage>> getPlaceGallery(int placeId);

  /// Emits when Souf360 changes the public places catalogue.
  Stream<void> watchPublishedPlaces();

  Future<void> submitVisitorPlace({
    required String name,
    required String mainCategory,
    String? subCategory,
    String? description,
    String? address,
    String? municipality,
    String? phone,
    String? mapLink,
    String? openingHours,
    Uint8List? imageBytes,
    String? imageFileName,
  });
}
