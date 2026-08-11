import '../../domain/entities/place_gallery_image.dart';

class PlaceGalleryImageModel extends PlaceGalleryImage {
  const PlaceGalleryImageModel({
    required super.id,
    required super.placeId,
    required super.imageUrl,
    super.title,
    super.description,
    super.isCover,
    super.sortOrder,
  });

  factory PlaceGalleryImageModel.fromJson(Map<String, dynamic> json) {
    final rawPlaceId = json['place_id'];
    final rawSortOrder = json['sort_order'];
    return PlaceGalleryImageModel(
      id: '${json['id'] ?? ''}',
      placeId:
          rawPlaceId is int ? rawPlaceId : int.tryParse('$rawPlaceId') ?? 0,
      imageUrl: (json['image_url'] as String?)?.trim() ?? '',
      title: _optionalText(json['title']),
      description: _optionalText(json['description']),
      isCover: json['is_cover'] == true,
      sortOrder: rawSortOrder is int
          ? rawSortOrder
          : int.tryParse('$rawSortOrder') ?? 0,
    );
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
