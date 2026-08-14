import '../../domain/entities/place_gallery_image.dart';

class PlaceGalleryImageModel extends PlaceGalleryImage {
  const PlaceGalleryImageModel({
    required super.id,
    required super.placeId,
    required super.imageUrl,
    super.title,
    super.description,
    required super.isCover,
    required super.sortOrder,
  });
  factory PlaceGalleryImageModel.fromJson(Map<String, dynamic> json) {
    return PlaceGalleryImageModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      placeId: json['place_id'] is int
          ? json['place_id']
          : int.tryParse(json['place_id'].toString()) ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      isCover: json['is_cover'] == true || json['is_cover'] == 'true',
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }
}
