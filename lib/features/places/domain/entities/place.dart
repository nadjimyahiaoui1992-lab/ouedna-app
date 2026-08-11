class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    this.imageUrl,
    this.rating,
    this.openingHours,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String? imageUrl;
  final double? rating;
  final String? openingHours;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}
