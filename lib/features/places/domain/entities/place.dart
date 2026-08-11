class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    this.subCategory,
    this.district,
    this.municipality,
    this.imageUrl,
    this.rating,
    this.openingHours,
    this.latitude,
    this.longitude,
    this.mapLink,
    this.phone,
    this.website,
    this.facebook,
    this.instagram,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String category;
  final String? subCategory;
  final String description;
  final String address;
  final String? district;
  final String? municipality;
  final String? imageUrl;
  final double? rating;
  final String? openingHours;
  final double? latitude;
  final double? longitude;
  final String? mapLink;
  final String? phone;
  final String? website;
  final String? facebook;
  final String? instagram;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get locationLabel {
    final values = [address, district, municipality]
        .where((value) => value?.trim().isNotEmpty == true)
        .map((value) => value!.trim())
        .toSet()
        .toList(growable: false);
    return values.isEmpty ? 'وادي سوف، الجزائر' : values.join('، ');
  }
}
