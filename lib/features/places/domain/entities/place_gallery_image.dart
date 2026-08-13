class PlaceGalleryImage {
  const PlaceGalleryImage({
    required this.id,
    required this.placeId,
    required this.imageUrl,
    this.title,
    this.description,
    required this.isCover,
    required this.sortOrder,
  });
  final int id;
  final int placeId;
  final String imageUrl;
  final String? title;
  final String? description;
  final bool isCover;
  final int sortOrder;
}
