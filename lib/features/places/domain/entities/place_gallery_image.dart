class PlaceGalleryImage {
  const PlaceGalleryImage({
    required this.id,
    required this.placeId,
    required this.imageUrl,
    this.title,
    this.description,
    this.isCover = false,
    this.sortOrder = 0,
  });

  final String id;
  final int placeId;
  final String imageUrl;
  final String? title;
  final String? description;
  final bool isCover;
  final int sortOrder;
}
